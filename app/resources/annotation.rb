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
            p.rdf_uri   item.uri
            p.name      item.prefLabel
            p.prefix    item.prefix
            p.domain    item.domain
          end
        end
      end

      class AnnotationResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :annotation
          entities :annotations, item, AnnotationSerializer

          link :self,       link_self(item.first.prefix)
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

      class AnnotationCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'annotation_collection'
          entities :annotations, item, AnnotationSerializer

          link :self,       link_self
          link :start,      link_start(item.first.prefix)
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
    end
  end
end
