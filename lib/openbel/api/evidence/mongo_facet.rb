require 'mongo'
require 'multi_json'
require_relative 'facet_api'
require_relative 'facet_filter'

module OpenBEL
  module Evidence

    class EvidenceFacets
      include FacetAPI
      include Mongo
      include FacetFilter

      def initialize(options = {})
        host             = options[:host]
        port             = options[:port]
        db               = options[:database]
        @db              = MongoClient.new(host, port).db(db)

        # Authenticate user if provided.
        username = options[:username]
        password = options[:password]
        if username && password
          auth_db = options[:authentication_database] || db
          @db.authenticate(username, password, nil, auth_db)
        end

        @evidence        = @db[:evidence]
        @evidence_facets = @db[:evidence_facets]
      end

      def create_facets(_id, query_hash)
        # create and save facets, identified by query
        facets_doc = _id.merge({
          :facets => evidence_facets(query_hash)
        })
        @evidence_facets.save(facets_doc, :j => true)

        # return facets document
        facets_doc
      end

      def find_facets(query_hash, filters)
        _id = {:_id => to_facets_id(filters)}
        @evidence_facets.find_one(_id) || create_facets(_id, query_hash)
      end

      def remove_facets_by_filters(filters = [], options = {})
        remove_spec =
          if filters.empty?
            { :_id => "" }
          else
            {
              :_id => {
                :$in => filters.map { |filter|
                  to_regexp(MultiJson.load(filter))
                }
              }
            }
          end
        @evidence_facets.remove(remove_spec, :j => true)
      end

      private

      def to_regexp(filter)
        filter_s = "#{filter['category']}|#{filter['name']}|#{filter['value']}"
        %r{.*#{Regexp.escape(filter_s)}.*}
      end


      def to_facets_id(filters)
        filters.map { |filter|
          "#{filter['category']}|#{filter['name']}|#{filter['value']}"
        }.sort.join(',')
      end

      def evidence_facets(query_hash = nil)
        pipeline =
          if query_hash.is_a?(Hash) && !query_hash.empty?
            [{:'$match' => query_hash}] + AGGREGATION_PIPELINE
          else
            AGGREGATION_PIPELINE
          end
        @evidence.aggregate(pipeline)
      end

      AGGREGATION_PIPELINE = [
        {
          :'$project' => {
            :_id => 0,
            :facets => 1
          }
        },
        {
          :'$unwind' => '$facets'
        },
        {
          :'$group' => {
            :_id => '$facets',
            :count => {
              :'$sum' => 1
            }
          }
        },
        {
          :'$sort' => {
            :count => -1
          }
        }
      ]
    end
  end
end
