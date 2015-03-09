require 'mongo'
require_relative 'api'
require_relative 'mongo_facet'

module OpenBEL
  module Evidence

    class Evidence
      include API
      include Mongo

      def initialize(options = {})
        host             = options.delete(:host)
        port             = options.delete(:port)
        db               = options.delete(:database)
        @db              = MongoClient.new(host, port).db(db)
        @collection      = @db[:evidence]
        @evidence_facets = EvidenceFacets.new(
          :host     => host,
          :port     => port,
          :database => db
        )
#        if @collection.index_information['TextIndex'].nil?
#          @collection.ensure_index(
#            {
#              "bel_statement"            => "text",
#              "biological_context.name"  => "text",
#              "biological_context.value" => "text",
#              "citation.name"            => "text",
#              "metadata.name"            => "text",
#              "metadata.value"           => "text",
#              "summary_text"             => "text"
#            },
#            {
#              "name"       => "TextIndex",
#              "background" => true,
#              "weights" => {
#                "bel_statement"            => 10,
#                "biological_context.name"  => 4,
#                "biological_context.value" => 10,
#                "citation.name"            => 2,
#                "metadata.name"            => 4,
#                "metadata.value"           => 6,
#                "summary_text"             => 8
#              }
#            }
#          )
#        end
      end

      def create_evidence(evidence)
        @collection.insert(evidence.to_h, :j => true)
      end

      def find_evidence_by_id(value)
        @collection.find_one(to_id(value))
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

        puts query_hash
        results = {
          :cursor => @collection.find(query_hash, query_opts)
        }
        if facet
          facets_doc = @evidence_facets.find_facets(query_hash, filters)
          results[:facets] = facets_doc["facets"]
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

      EMPTY_HASH = {}

      def to_query(filters = [])
        if !filters || filters.empty?
          return EMPTY_HASH
        end

        query_hash = {}
        filters.each do |filter|
          category = filter['category']
          name     = filter['name']
          value    = filter['value']

          if category == 'biological_context'
            context = query_hash.fetch('biological_context', nil)
            if !context
              context = {
                :$all => []
              }
              query_hash['biological_context'] = context
            end

            context[:$all] << {
              :name  => name.to_s,
              :value => value.to_s
            }
          else
            query_hash["#{filter['category']}.#{filter['name']}"] = filter['value'].to_s
          end
        end

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
    end
  end
end
