require_relative 'base'

module OpenBEL
  module Resource
    module Annotations

      VOCABULARY_RDF = 'http://www.openbel.org/vocabulary/'

      class AnnotationValueSearchResult < BEL::Resource::AnnotationValue

        def match_text=(match_text)
          @match_text = match_text
        end

        def match_text
          @match_text
        end
      end

      class AnnotationSerializer < BaseSerializer
#        adapter Oat::Adapters::HAL
        schema do
          type     :annotation
          property :rdf_uri,    item.uri.to_s
          property :name,       item.prefLabel
          property :prefix,     item.prefix
          property :domain,     item.domain
        end
      end

      class AnnotationResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type     :annotation
          property :annotation, item
          link     :self,       link_self(item[:prefix])
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
            :type => :annotation_collection,
            :href => "#{base_url}/api/annotations"
          }
        end
      end

      class AnnotationCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type     :annotation_collection
          property :annotation_collection, item
          link     :self,                  link_self
          link     :start,                 link_start
        end

        private

        def link_self
          {
            :type => :annotation_collection,
            :href => "#{base_url}/api/annotations"
          }
        end

        def link_start
          {
            :type => :start,
            :href => "#{base_url}/api/annotations/values"
          }
        end
      end

      class AnnotationValueSerializer < BaseSerializer
        #adapter Oat::Adapters::HAL
        schema do
          type     :annotation_value
          property :rdf_uri,         item.uri.to_s
          property :type,            [item.type].flatten.map(&:to_s)
          property :identifier,      item.identifier
          property :name,            item.prefLabel
          entity   :annotation,      item.annotation, AnnotationSerializer

          # Support inclusion of the matched text when annotation values are filtered by
          # a full-text search.
          if item.match_text
            property :match_text,    item.match_text
          end

          setup(item)
          link     :self,            link_self
          link     :collection,      link_annotation
        end

        private

        def setup(item)
          @annotation_id, @annotation_value_id = URI(item.uri).path.split('/')[3..-1]
        end

        def link_self
          {
            :type => :annotation_value,
            :href => "#{base_url}/api/annotations/#{@annotation_id}/values/#{@annotation_value_id}"
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
          type     :annotation_value
          property :annotation_value, item
        end
      end

      class AnnotationValueCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type     :annotation_value_collection
          property :annotation_value_collection, item
        end
      end
    end
  end
end
