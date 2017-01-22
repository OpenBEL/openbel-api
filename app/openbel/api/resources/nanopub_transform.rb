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
              nanopub.experiment_context.values =
                experiment_context.values.flat_map { |annotation|
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
            annotation_label  = annotation.pref_label.first.to_s
            annotation_prefix = annotation.prefix.first.to_s

            if value.respond_to?(:each)
              value.map { |v|
                annotation_value = annotation.find(v).first

                if annotation_value
                  identifier  = annotation_value.identifier.first.to_s
                  value_label = annotation_value.pref_label.first.to_s
                  {
                    :name  => annotation_label,
                    :value => value_label,
                    :uri   => ANNOTATION_VALUE_URI % [
                      base_url,
                      annotation_prefix,
                      identifier
                    ]
                  }
                else
                  {
                    :name  => annotation_label,
                    :value => v
                  }
                end
              }
            else
              annotation_value = annotation.find(value).first
              identifier       = annotation_value.identifier.first.to_s
              value_label      = annotation_value.pref_label.first.to_s
              if annotation_value
                {
                  :name  => annotation_label,
                  :value => value_label,
                  :uri   => ANNOTATION_VALUE_URI % [
                    base_url,
                    annotation_prefix,
                    identifier
                  ]
                }
              else
                {
                  :name  => annotation_label,
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
