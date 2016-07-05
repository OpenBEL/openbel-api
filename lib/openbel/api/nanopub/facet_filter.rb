require 'multi_json'

module OpenBEL
  module Nanopub
    module FacetFilter

      EMPTY = []
      NANOPUB_PARTS = [:citation, :experiment_context, :metadata]

      def map_nanopub_facets(nanopub)
        NANOPUB_PARTS.reduce([]) { |facets, nanopub_part|
          part = nanopub.send(nanopub_part)
          new_facets = self.send(:"map_#{nanopub_part}_facets", part)
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
          }.select { |(_, _, value)|
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
          }.select { |_, _, value|
            value != nil
          }.map { |filter|
            self.make_filter(*filter)
          }
        else
          EMPTY
        end
      end

      def make_filter(category, name, value)
        {
          :category => category,
          :name     => name,
          :value    => value
        }
      end
    end
  end
end
