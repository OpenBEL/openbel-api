require 'multi_json'

module OpenBEL
  module Evidence
    module FacetFilter

      EMPTY = []
      EVIDENCE_PARTS = [:citation, :experiment_context, :metadata]

      def map_evidence_facets(evidence)
        EVIDENCE_PARTS.reduce([]) { |facets, evidence_part|
          part = evidence.send(evidence_part)
          new_facets = self.send(:"map_#{evidence_part}_facets", part)
          facets.concat(new_facets)
        }
      end

      def map_citation_facets(citation)
        if citation and citation.id
          [
            self.make_filter(:citation, :id, citation.id)
          ]
        else
          EMPTY
        end
      end

      def map_experiment_context_facets(experiment_context)
        if experiment_context
          experiment_context.flat_map { |annotation|
            name  = annotation[:name]
            value = annotation[:value]
            if value.respond_to?(:each)
              value.map { |v|
                [:experiment_context, name, v]
              }
            else
              # HACK: nested array will be flattened out by flat_map;
              # otherwise we would have each data value unrolled
              [[:experiment_context, name, value]]
            end
          }.select { |(category, name, value)|
            value != nil
          }.map { |filter|
            self.make_filter(*filter)
          }
        else
          EMPTY
        end
      end

      def map_metadata_facets(metadata)
        if metadata
          metadata.flat_map { |name, value|
            if value.respond_to?(:each)
              value.map { |v|
                [:metadata, name, v]
              }
            else
              # HACK: nested array will be flattened out by flat_map;
              # otherwise we would have each data value unrolled
              [[:metadata, name, value]]
            end
          }.select { |category, name, value|
            value != nil
          }.map { |filter|
            self.make_filter(*filter)
          }
        else
          EMPTY
        end
      end

      def make_filter(category, name, value)
        MultiJson.dump({
          :category => category,
          :name     => name,
          :value    => value,
        })
      end
    end
  end
end
