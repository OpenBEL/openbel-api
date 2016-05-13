#!/usr/bin/env jruby

# Mongo migration:
# - Drops the now unused "nanopub_facets" collection.
# - Replaced by the "nanopub_facet_cache" collection plus individual UUID cache collections.
# - Idempotent (i.e. Safe to run multiple times.)
#

require 'openbel/api/config'
require 'openbel/api/version'

VERSION_REQUIREMENT = /^0.6/
ACTIVE_VERSION      = OpenBEL::Version::STRING

ENV['OPENBEL_API_CONFIG_FILE'] ||= (ARGV.first || ENV['OPENBEL_API_CONFIG_FILE'])

unless ENV['OPENBEL_API_CONFIG_FILE']
  $stderr.puts "usage: drop_unused_collection.rb [CONFIG FILE]\n"
  $stderr.puts "Alternatively set the environment variable OPENBEL_API_CONFIG_FILE"
  exit 1
end

def setup_mongo(cfg)
  require 'mongo'

	host = cfg[:host]
	port = cfg[:port]
	db   = Mongo::MongoClient.new(host, port,
    :op_timeout => 300
  ).db(cfg[:database])

	# Authenticate user if provided.
	username = cfg[:username]
	password = cfg[:password]
	if username && password
		auth_db = cfg[:authentication_database] || db
		db.authenticate(username, password, nil, auth_db)
	end

  db
end

def migrate(mongo)
  if mongo.collection_names.include?('nanopub_facets')
    mongo.drop_collection('nanopub_facets')
    puts %Q{Dropped "nanopub_facets" collection (success).}
  else
    puts %Q{The "nanopub_facets" collection does not exist. Nothing to migrate (success).}
  end

  true
end

if ACTIVE_VERSION =~ VERSION_REQUIREMENT
  cfg = OpenBEL::Config.load!
  migrate(
    setup_mongo(cfg[:nanopub_store][:mongo])
  )
  exit 0
else
  $stderr.puts %Q{Migration is intended for version "#{VERSION_REQUIREMENT}".}
  $stderr.puts %Q{Version "#{ACTIVE_VERSION}" is currently installed.}
  exit 1
end
