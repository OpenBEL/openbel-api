require_relative 'api'
require_relative 'model'
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
        convert_evidence(@evidence.find_one(to_id(value)))
      end

      def update_evidence_by_id(value, evidence)
        evidence_h = evidence.to_h
        evidence_h[:_id] = value
        @evidence.save(evidence_h)
      end

      def delete_evidence_by_id(value)
        @evidence.remove({
          :_id => to_id(value)
        })
      end

      private

      def convert_evidence(evidence)
        if evidence
          OpenBEL::Model::Evidence::EvidenceMongo.new(evidence)
        else
          nil
        end
      end

      def to_id(value)
        BSON::ObjectId(value.to_s)
      end
    end
  end
end
