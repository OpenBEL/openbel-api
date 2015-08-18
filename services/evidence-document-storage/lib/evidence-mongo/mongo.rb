require 'mongo'
require 'evidence/api'
require_relative 'mongo_facet'

module OpenBEL
  module Evidence

    class Evidence
      include API
      include Mongo

      def initialize(options = {})
        host             = options[:host]
        port             = options[:port]
        db               = options[:database]
        @db              = MongoClient.new(host, port).db(db)

        # rebuild collection if option enabled and the collection exists
        @db[:evidence].drop if options[:rebuild] && @db[:evidence]

        @evidence      = @db[:evidence]
        @evidence.ensure_index(
          {
            :'metadata.__uuid__' => ASCENDING
          },
          {
            :background => true,
            :unique     => true
          }
        )

        @evidence_facets = EvidenceFacets.new(options)
      end

      def create_evidence(evidence)
        # insert evidence; acknowledge journal
        #_id = @evidence.insert(evidence.to_h, :j => true)
        _id = @evidence.insert(evidence.to_h, :w => 0, :j => false)

        # TODO This should be done in the "evidence facets" component.
        # remove evidence_facets after insert to facets
        # remove_evidence_facets(_id)

        _id
      end

      def find_evidence_by_id(value)
        @evidence.find_one(to_id(value))
      end

      def find_evidence_by_uuid(value, projection = {})
        @evidence.find_one(
          {
            :'metadata.__uuid__' => value.to_s
          },
          {
            :fields => projection
          }
        )
      end

      def find_evidence(filters = [], offset = 0, length = 0, facet = false)
        query_hash = to_query(filters)
        query_opts = query_options(
          query_hash,
          :skip  => offset,
          :limit => length,
          :sort  => [
            [:bel_statement, :asc]
          ]
        )

        results = {
          :cursor => @evidence.find(query_hash, query_opts)
        }
        if facet
          facets_doc = @evidence_facets.find_facets(query_hash, filters)
          results[:facets] = facets_doc["facets"]
        end

        results
      end

      def update_evidence_by_uuid(uuid, evidence)
        evidence_h = evidence.to_h
        (evidence_h[:metadata] ||= {})[:__uuid__] = uuid

        stored = find_evidence_by_uuid(uuid, {:_id => 1})
        if stored
          evidence_h[:_id] = stored['_id']
        end

        # save evidence; acknowledge journal
        @evidence.save(evidence_h, :j => true)

        # TODO This should be done in the "evidence facets" component.
        # remove evidence_facets after update to facets
        # remove_evidence_facets(_id)

        nil
      end

      def delete_evidence_by_uuid(uuid)
        # TODO This should be done in the "evidence facets" component.
        # remove evidence_facets before evidence removal
        # remove_evidence_facets(_id)

        # remove evidence
        @evidence.remove(
          {
            :'metadata.__uuid__' => uuid
          },
          :j => true
        )
      end

      private

      EMPTY_HASH = {}

      def to_query(filters = [])
        if !filters || filters.empty?
          return EMPTY_HASH
        end

        query_hash = {
          :$and => filters.map { |filter|
            category = filter['category']
            name     = filter['name']
            value    = filter['value']

            if category == 'experiment_context'
              {
                :experiment_context => {
                  :$elemMatch => {
                    :name  => name.to_s,
                    :value => value.to_s
                  }
                }
              }
            else
              {
                "#{filter['category']}.#{filter['name']}" => filter['value'].to_s
              }
            end
          }
        }

        fts_search_value = query_hash.delete("fts.search")
        if fts_search_value
          query_hash[:$text] = {
            :$search => fts_search_value
          }
        end

        query_hash
      end

      def query_options(query_hash, options = {})

        if query_hash[:$text]
          options[:fields] = [
            {
              :score => {
                :$meta => "textScore"
              }
            }
          ]
          options[:sort].unshift(
            [:score, {:$meta => "textScore"}]
          )
        end
        options
      end

      def to_id(value)
        BSON::ObjectId(value.to_s)
      end

      def remove_evidence_facets(_id)
        evidence = @evidence.find_one(_id, {
          :fields => [ 'facets' ]
        })

        if evidence && evidence.has_key?('facets')
          @evidence_facets.remove_facets_by_filters(evidence['facets'])
          @evidence_facets.remove_facets_by_filters 
        end
      end
    end
  end
end
