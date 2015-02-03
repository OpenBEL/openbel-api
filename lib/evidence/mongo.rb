require_relative 'api'
require 'mongo'

module OpenBEL
  module Evidence

    class Evidence
      include API
      include Mongo

      def initialize(options = {})
        host      = options.delete(:host)
        port      = options.delete(:port)
        db        = options.delete(:database)
        @db       = MongoClient.new(host, port).db(db)
        @evidence = @db.collection(:evidence)
      end

      def create_evidence(evidence)
        @evidence.insert(evidence.to_h)
      end

      def find_evidence_by_id(value)
        @evidence.find_one(to_id(value))
      end

      def find_evidence_by_query(query, offset = 0, length = 100)
        [
          @evidence.find(query, :skip => offset, :limit => length),
          facets(query)
        ]
      end

      def update_evidence_by_id(value, evidence)
        evidence_h = evidence.to_h
        evidence_h[:_id] = BSON::ObjectId(value)
        puts evidence_h
        @evidence.save(evidence_h)
      end

      def delete_evidence_by_id(value)
        @evidence.remove({
          :_id => to_id(value)
        })
      end

      private

      def to_id(value)
        BSON::ObjectId(value.to_s)
      end

      def facets(query)
        @evidence.aggregate([
          {
            :'$match' => query
          },
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
              :_id => '$facets.filter',
              :count => {
                :'$sum' => '$facets.count'
              }
            }
          },
          {
            :'$sort' => {
              :count => -1
            }
          }
        ])
      end
    end
  end
end
