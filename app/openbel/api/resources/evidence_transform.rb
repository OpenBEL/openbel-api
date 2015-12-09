require 'bel'

module OpenBEL
  module Resource
    module Evidence

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

        def transform_evidence!(evidence, base_url)
          if evidence
            experiment_context = evidence.experiment_context
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
                :name  => annotation.prefLabel,
                :value => value.map { |v|
                  mapped = annotation.find(v).first
                  mapped ? mapped.prefLabel : v
                }
              }
            else
              annotation_value = annotation.find(value).first
              if annotation_value
                {
                  :name  => annotation.prefLabel,
                  :value => annotation_value.prefLabel,
                  :uri   => ANNOTATION_VALUE_URI % [
                    base_url,
                    annotation.prefix,
                    annotation_value.identifier
                  ]
                }
              else
                {
                  :name  => annotation.prefLabel,
                  :value => value
                }
              end
            end
          end
        end

        def free_annotation(name, value)
          {
            :name  => normalize_annotation_name(name),
            :value => value
          }
        end

        def normalize_annotation_name(name, options = {})
          name_s = name.to_s

          if name_s.empty?
            nil
          else
            name_s.
              split(%r{[^a-zA-Z0-9]+}).
              map! { |word| word.capitalize }.
              join
          end
        end
      end

      class AnnotationGroupingTransform

        ExperimentContext = ::BEL::Model::ExperimentContext

        def transform_evidence!(evidence)
          experiment_context = evidence.experiment_context
          if experiment_context != nil
            evidence.experiment_context = ExperimentContext.new(
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
