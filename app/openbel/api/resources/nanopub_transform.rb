require 'bel'

module OpenBEL
  module Resource
    module Nanopub

      class AnnotationTransform

        SERVER_PATTERN = %r{/api/annotations/([^/]*)/values/([^/]*)/?}
        RDFURI_PATTERN = %r{/bel/namespace/([^/]*)/([^/]*)/?}
        URI_PATTERNS = [
          %r{/api/annotations/([^/]*)/values/([^/]*)/?},
          %r{/bel/namespace/([^/]*)/([^/]*)/?}
        ]
        ANNOTATION_VALUE_URI = "%s/api/annotations/%s/values/%s"

        def initialize(annotations)
          @annotations = annotations
        end

        def transform_nanopub!(nanopub, base_url)
          if nanopub
            experiment_context = nanopub.experiment_context
            if experiment_context != nil
              experiment_context.values.map! { |annotation|
                transform_annotation(annotation, base_url)
              }
            end
          end
        end

        def transform_annotation(annotation, base_url)
          if annotation[:uri]
            transformed = transform_uri(annotation[:uri], base_url)
            return transformed if transformed != nil
          end

          if annotation[:name] && annotation[:value]
            name  = annotation[:name]
            value = annotation[:value]
            transform_name_value(name, value, base_url)
          elsif annotation.respond_to?(:each)
            name  = annotation[0]
            value = annotation[1]
            transform_name_value(name, value, base_url)
          end
        end

        private

        def transform_uri(uri, base_url)
          URI_PATTERNS.map { |pattern|
            match = pattern.match(uri)
            match ? transform_name_value(match[1], match[2], base_url) : nil
          }.compact.first
        end

        def transform_name_value(name, value, base_url)
          structured_annotation(name, value, base_url) || free_annotation(name, value)
        end

        def structured_annotation(name, value, base_url)
          annotation = @annotations.find(name).first
          if annotation
            if value.respond_to?(:each)
              {
                :name  => annotation.prefLabel.to_s,
                :value => value.map { |v|
                  mapped = annotation.find(v).first
                  mapped ? mapped.prefLabel.to_s : v
                }
              }
            else
              annotation_value = annotation.find(value).first
              if annotation_value
                {
                  :name  => annotation.prefLabel.to_s,
                  :value => annotation_value.prefLabel.to_s,
                  :uri   => ANNOTATION_VALUE_URI % [
                    base_url,
                    annotation.prefix.to_s,
                    annotation_value.identifier.to_s
                  ]
                }
              else
                {
                  :name  => annotation.prefLabel.to_s,
                  :value => value
                }
              end
            end
          end
        end

        def free_annotation(name, value)
          {
            :name  => name,
            :value => value
          }
        end

      end

      class AnnotationGroupingTransform

        ExperimentContext = ::BEL::Nanopub::ExperimentContext

        def transform_nanopub!(nanopub)
          experiment_context = nanopub.experiment_context
          if experiment_context != nil
            nanopub.experiment_context = ExperimentContext.new(
              experiment_context.group_by { |annotation|
                annotation[:name]
              }.values.map do |grouped_annotation|
                {
                  :name  => grouped_annotation.first[:name],
                  :value => grouped_annotation.flat_map { |annotation|
                    annotation[:value]
                  },
                  :uri   => grouped_annotation.flat_map { |annotation|
                    annotation[:uri]
                  }
                }
              end
            )
          end
        end
      end
    end
  end
end
