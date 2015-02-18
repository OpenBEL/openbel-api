require_relative 'base'

module OpenBEL
  module Resource
    module Annotations

      VOCABULARY_RDF = 'http://www.openbel.org/vocabulary/'

      class AnnotationSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :annotation
          properties do |p|
            p.name      item.prefLabel
            p.prefix    item.prefix
            p.domain    item.domain
          end

          link :self,       link_self(item.prefix)
          link :collection, link_collection
        end

        private

        def link_self(id)
          {
            :type => :annotation,
            :href => "#{base_url}/api/annotations/#{id}"
          }
        end

        def link_collection
          {
            :type => :'annotation_collection',
            :href => "#{base_url}/api/annotations"
          }
        end
      end

      class AnnotationResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :annotation
          properties do |p|
            p.annotations   item
          end
        end
      end

      class AnnotationCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'annotation_collection'
          properties do |p|
            p.annotations   item
          end

          link :self,       link_self
          link :start,      link_start(item.first[:prefix])
        end

        private

        def link_self
          {
            :type => :'annotation_collection',
            :href => "#{base_url}/api/annotations"
          }
        end

        def link_start(prefix)
          {
            :type => :function,
            :href => "#{base_url}/api/annotations/#{prefix}"
          }
        end
      end

      class AnnotationValueSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :annotation_value

          properties do |p|
            p.type           item.type ? item.type.sub(VOCABULARY_RDF, '') : nil
            p.identifier     item.identifier
            p.name           item.prefLabel
          end

          setup(item)
          link :self,           link_self
          link :collection,     link_annotation
        end

        private

        def setup(item)
          parts = URI(item.uri).path.split('/')[3..-1]
          @annotation_id = parts[0]
          @annotation_value_id = parts.join('/')
        end

        def link_self
          {
            :type => :annotation_value,
            :href => "#{base_url}/api/annotations/#{@annotation_value_id}"
          }
        end

        def link_annotation
          {
            :type => :annotation,
            :href => "#{base_url}/api/annotations/#{@annotation_id}"
          }
        end
      end

      class AnnotationValueResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :annotation_value
          properties do |p|
            p.annotation_values item
          end
        end
      end

      class AnnotationValueCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :annotation_value_collection
          properties do |p|
            p.annotation_values item
          end
        end
      end
    end
  end
end
