require_relative 'base'

module OpenBEL
  module Resource
    module Namespaces

      VOCABULARY_RDF = 'http://www.openbel.org/vocabulary/'

      class NamespaceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :namespace
          properties do |p|
            p.rdf_uri   item.uri
            p.name      item.prefLabel
            p.prefix    item.prefix
            p.type      item.type ? item.type.sub(VOCABULARY_RDF, '') : nil
          end
        end
      end

      class NamespaceResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'namespace'
          entities :namespaces, item, NamespaceSerializer

          link :self,       link_self(item.first.prefix)
          link :collection, link_collection
        end

        private

        def link_self(id)
          {
            :type => :namespace,
            :href => "#{base_url}/api/namespaces/#{id}"
          }
        end

        def link_collection
          {
            :type => :'namespace_collection',
            :href => "#{base_url}/api/namespaces"
          }
        end
      end

      class NamespaceCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'namespace_collection'
          entities :namespaces, item, NamespaceSerializer

          link :self,       link_self
          link :start,      link_start(item.first.prefix)
        end

        private

        def link_self
          {
            :type => :'namespace_collection',
            :href => "#{base_url}/api/namespaces"
          }
        end

        def link_start(prefix)
          {
            :type => :function,
            :href => "#{base_url}/api/namespaces/#{prefix}"
          }
        end
      end

      class NamespaceValueSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'namespace_value'
          properties do |p|
            p.rdf_uri       item.uri
            p.type          item.type ? item.type.sub(VOCABULARY_RDF, '') : nil
            p.identifier    item.identifier
            p.title         item.title
            p.species       item.fromSpecies
            p.namespace_uri item.inScheme
          end
        end
      end

      class NamespaceValueResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'namespace_value'
          parts = URI(item.first.uri).path.split('/')[3..-1]
          namespace_id = parts[0]
          namespace_value_id = parts.join('/')
          entities :'namespace_values', item, NamespaceValueSerializer

          link :self,       link_self(namespace_value_id)
          link :collection, link_namespace(namespace_id)
          link :item,       [
            link_equivalents(namespace_value_id),
            link_orthologs(namespace_value_id)
          ]
        end

        private

        def link_self(id)
          {
            :type => :'namespace_value',
            :href => "#{base_url}/api/namespaces/#{id}"
          }
        end

        def link_namespace(id)
          {
            :type => :namespace,
            :href => "#{base_url}/api/namespaces/#{id}"
          }
        end

        def link_equivalents(id)
          {
            :type => :'namespace_value_collection',
            :href => "#{base_url}/api/namespaces/#{id}/equivalents"
          }
        end

        def link_orthologs(id)
          {
            :type => :'namespace_value_collection',
            :href => "#{base_url}/api/namespaces/#{id}/orthologs"
          }
        end
      end

      class NamespaceValueCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'namespace_value_collection'
          entities :'namespace_values', item, NamespaceValueSerializer
        end
      end

      class ValueEquivalenceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'value_equivalence'
          properties do |p|
            p.value         item.value
            p.type          item.type ? item.type.sub(VOCABULARY_RDF, '') : nil
            p.identifier    item.identifier
            p.title         item.title
            p.species       item.fromSpecies
            p.namespace_uri item.inScheme
          end

          entities :equivalences, item.equivalences, NamespaceValueSerializer
        end
      end
    end
  end
end
# vim: ts=2 sw=2
