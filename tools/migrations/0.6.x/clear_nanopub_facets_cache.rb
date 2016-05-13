#!/usr/bin/env jruby

# Clears out nanopub facet caches that may have been built before nanopub
# documents were migrated for 0.6.0.
#
# Mongo migration:
# - Drops all nanopub_facet_cache_* collections.
# - Removes all documents from nanopub_facet_caches that referenced the
#   dropped collections.
#

require 'openbel/api/config'
require 'openbel/api/version'

VERSION_REQUIREMENT = /^0.6/
ACTIVE_VERSION      = OpenBEL::Version::STRING

ENV['OPENBEL_API_CONFIG_FILE'] ||= (ARGV.first || ENV['OPENBEL_API_CONFIG_FILE'])

unless ENV['OPENBEL_API_CONFIG_FILE']
  $stderr.puts "usage: clear_nanopub_facets_cache.rb [CONFIG FILE]\n"
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
  if mongo.collection_names.include?('nanopub_facet_cache')
    mongo['nanopub_facet_cache'].remove({})
    puts %Q{Removing documents from "nanopub_facet_cache" (success).}
  end

  mongo.collection_names.select { |name|
    name =~ /^nanopub_facet_cache_[0-9a-f\-]+$/
  }.each do |name|
    mongo.drop_collection(name)
    puts %Q{Dropped "#{name}" collection (success).}
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
