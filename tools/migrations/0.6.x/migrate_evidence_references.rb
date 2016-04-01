#!/usr/bin/env jruby

# Mongo migration:
# - Converts "evidence.references.namespaces" from JSON objects to arrays of objects in each document.
# - Converts "evidence.references.annotations" from JSON objects to arrays of objects in each document.
# - Idempotent (i.e. Safe to run multiple times.)

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
      references = doc['references']
      next if references == nil

      # handle namespaces
      namespaces = references.fetch('namespaces', [])
      if namespaces.is_a?(Hash)
        namespaces = references.fetch('namespaces', []).map do |keyword, uri|
          {
            :keyword => keyword,
            :uri     => uri
          }
        end
      end

      # handle annotations
      annotations = references.fetch('annotations', [])
      if annotations.is_a?(Hash)
        annotations = references.fetch('annotations', []).map do |keyword, hash|
          {
            :keyword => keyword,
            :type    => hash['type'],
            :domain  => hash['domain']
          }
        end
      end

      evidence_collection.update(
        {:_id => doc['_id']},
        {
          :$set => {
            :references => {
              :annotations => annotations,
              :namespaces  => namespaces
            }
          }
        }
      )
      count += 1
      puts "...#{count} evidence migrated" if count > 0 && (count % 100).zero?
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
  $stdout.puts %Q{Successfully migrated "references" field of documents in "evidence" collection from objects to arrays of objects.}
  exit 0
else
  $stderr.puts %Q{Migration is intended for version "#{VERSION_REQUIREMENT}".}
  $stderr.puts %Q{Version "#{ACTIVE_VERSION}" is currently installed.}
  exit 1
end
