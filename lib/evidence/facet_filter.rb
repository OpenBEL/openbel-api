require 'multi_json'

module OpenBEL
  module Evidence
    module FacetFilter

      EMPTY = []
      EVIDENCE_PARTS = ['citation', 'biological_context', 'metadata']

      def map_evidence_facets(evidence)
        EVIDENCE_PARTS.reduce([]) { |facets, evidence_part|
          part = evidence[evidence_part]
          facets.concat(self.send(:"map_#{evidence_part}_facets", part))
        }
      end

      def map_citation_facets(citation)
        if citation and citation['id']
          [
            self.make_filter(:citation, :id, citation['id'])
          ]
        else
          EMPTY
        end
      end

      def map_biological_context_facets(biological_context)
        if biological_context
          biological_context.flat_map { |annotation|
            name  = annotation[:name]
            value = annotation[:value]
            if value.respond_to?(:each)
              value.map { |v|
                self.make_filter(:biological_context, name, v)
              }
            else
              self.make_filter(:biological_context, name, value)
            end
          }
        else
          EMPTY
        end
      end

      def map_metadata_facets(metadata)
        if metadata
          metadata.map { |name, value|
            self.make_filter(:metadata, name, value)
          }
        else
          EMPTY
        end
      end

      def make_filter(category, name, value, count = 1)
        {
          :filter => MultiJson.dump({
            :category => category,
            :name     => name,
            :value    => value,
          }),
          :count  => 1
        }
      end
    end
  end
end
