require 'mongo'
require_relative 'api'
require_relative 'mongo_facet_aggregation'

module OpenBEL
  module Evidence

    class Evidence
      include API
      include Mongo
      include Facets

      def initialize(options = {})
        host      = options.delete(:host)
        port      = options.delete(:port)
        db        = options.delete(:database)
        @db       = MongoClient.new(host, port).db(db)
        @collection = @db.collection(:evidence)
        @collection.ensure_index(
          :"$**" => "text"
        )
      end

      def create_evidence(evidence)
        @collection.insert(evidence.to_h, :j => true)
      end

      def find_evidence_by_id(value)
        @collection.find_one(to_id(value))
      end

      def find_evidence_by_query(query_hash = nil, offset = 0, length = 0, facet = false)
        if query_hash != nil && !query_hash.is_a?(Hash)
          fail ArgumentError.new("query_hash is not of type nil or Hash")
        end

        query_hash.keys.each do |key|
          if key.to_s.start_with?('biological_context.')
            # split into two parts
            _, name = key.split('.', 2)

            # lookup value
            value   = query_hash[key]

            # add elemMatch query on name/value
            query_hash['biological_context'] = {
              :$elemMatch => {
                :name  => name,
                :value => value
              }
            }

            # delete previous "category.name" key
            query_hash.delete(key)
          end
        end

        results = {
          :cursor => @collection.find(query_hash, :skip => offset, :limit => length)
        }
        if facet
          results[:facets] = evidence_facets(query_hash)
        end

        results
      end

      def update_evidence_by_id(value, evidence)
        evidence_h = evidence.to_h
        evidence_h[:_id] = BSON::ObjectId(value)
        @collection.save(evidence_h, :j => true)
      end

      def delete_evidence_by_id(value)
        @collection.remove(
          {
            :_id => to_id(value)
          },
          :j => true
        )
      end

      private

      def to_id(value)
        BSON::ObjectId(value.to_s)
      end
    end
  end
end
