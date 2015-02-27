require 'active_support'
require 'active_support/inflector/transliterate'

module OpenBEL
  module Resource
    module Evidence

      class AnnotationTransform
        include ActiveSupport::Inflector

        URI_PATTERNS = [
          %r{/api/annotations/([^/]*)/values/([^/]*)/?}, #Route URI
          %r{/bel/namespace/([^/]*)/([^/]*)/?},   #RDF   URI
        ]

        def initialize(annotation_api)
          @annotation_api = annotation_api
        end

        def transform_evidence(evidence)
          if evidence == nil
            nil
          else
            context = evidence['biological_context']
            if context != nil
              context.map! { |annotation|
                transform_annotation(annotation)
              }
            end

            evidence
          end
        end

        def transform_annotation(annotation)
          if annotation['uri']
            transform_uri(annotation['uri'])
          elsif annotation['name'] && annotation['value']
            name  = annotation['name']
            value = annotation['value']
            transform_name_value(name, value)
          else
            nil
          end
        end

        private

        def transform_uri(uri)
          URI_PATTERNS.each do |pattern|
            match = pattern.match(uri)
            if match
              return transform_name_value(match[1], match[2])
            end
          end
        end

        def transform_name_value(name, value)
          structured_annotation(name, value) || free_annotation(name, value)
        end

        def structured_annotation(name, value)
          annotation = @annotation_api.find_annotation(name)
          if annotation
            annotation_value = @annotation_api.find_annotation_value(annotation, value)
            if annotation_value
              return {
                :name  => annotation.prefLabel,
                :value => annotation_value.prefLabel
              }
            end
          end

          nil
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
            transliterate(name_s).
              gsub(%r{[^a-zA-Z0-9]}, ' ').
              split(' ').
              map(&:capitalize).
              join
          end
        end
      end

      class AnnotationGroupingTransform

        def transform_evidence(evidence)
          context = evidence['biological_context']
          if context != nil
            evidence['biological_context'] = context.group_by { |annotation|
              annotation[:name]
            }.values.map do |grouped_annotation|
              {
                :name  => grouped_annotation.first[:name],
                :value => grouped_annotation.map { |annotation|
                  annotation[:value]
                }
              }
            end
          end

          evidence
        end
      end
    end
  end
end
