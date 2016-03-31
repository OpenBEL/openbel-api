#!/usr/bin/env jruby

# Mongo migration:
# - Converts "evidence.facets" from JSON strings to objects in the document:
# - Each facet will be expanded from a JSON string to:
# {
#   category: "...",
#   name: "...",
#   value: "..."
# }
# - Idempotent (i.e. Safe to run multiple times.)
#

require 'openbel/api/config'
require 'openbel/api/version'

VERSION_REQUIREMENT = /^0.6/
ACTIVE_VERSION      = OpenBEL::Version::STRING

ENV['OPENBEL_API_CONFIG_FILE'] ||= (ARGV.first || ENV['OPENBEL_API_CONFIG_FILE'])

unless ENV['OPENBEL_API_CONFIG_FILE']
  $stderr.puts "usage: migrate_evidence_facets.rb [CONFIG FILE]\n"
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
  require 'multi_json'

  count   = 0
  skipped = 0
  evidence_collection = mongo[:evidence]
  evidence_collection.find do |cursor|
    cursor.each do |doc|
      facets = doc['facets']
      unless facets.empty?
        skip = true
        facets.map! do |facet|
          if facet.is_a?(String)
            skip = false
            MultiJson.load(facet)
          else
            facet
          end
        end

        if skip
          skipped += 1
        else
          evidence_collection.update(
            {:_id => doc['_id']},
            {
              :$set => {
                :facets => facets
              }
            }
          )
          count += 1
        end
        puts "...#{count} evidence migrated" if count > 0 && (count % 100).zero?
      end
    end
  end

  puts "Total of #{count} evidence migrated. Skipped #{skipped} evidence (success)."
  true
end

if ACTIVE_VERSION =~ VERSION_REQUIREMENT
  cfg = OpenBEL::Config.load!
  migrate(
    setup_mongo(cfg[:evidence_store][:mongo])
  )
  $stdout.puts %Q{Successfully migrated "facets" field of documents in "evidence" collection from strings to full objects.}
  exit 0
else
  $stderr.puts %Q{Migration is intended for version "#{VERSION_REQUIREMENT}".}
  $stderr.puts %Q{Version "#{ACTIVE_VERSION}" is currently installed.}
  exit 1
end
