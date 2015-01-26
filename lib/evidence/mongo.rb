require_relative 'api'
require_relative 'model'
require 'mongo'

module OpenBEL
  module Evidence

    class Evidence
      include API

      def initialize(options = {})
        host     = options.delete(:host)
        port     = options.delete(:port)
        db       = options.delete(:database)
        @db      = MongoClient.new(host, port).db(db)
      end

      def create_evidence(evidence)
        @db.insert(evidence.to_h)
      end
    end
  end
end
