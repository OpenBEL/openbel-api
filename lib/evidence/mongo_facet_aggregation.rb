require 'mongo'

module OpenBEL
  module Evidence
    module Facets

      def evidence_facets(query_hash = nil)
        pipeline =
          if query_hash.is_a?(Hash) && !query_hash.empty?
            pipeline = [{:'$match' => query_hash}] + AGGREGATION_PIPELINE
          else
            AGGREGATION_PIPELINE
          end
        @collection.aggregate(pipeline)
      end

      private

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
