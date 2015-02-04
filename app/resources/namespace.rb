require_relative 'base'

module OpenBEL
  module Resource
    module Namespaces

      VOCABULARY_RDF = 'http://www.openbel.org/vocabulary/'

      class NamespaceJsonSerializer < BaseSerializer
        adapter Oat::Adapters::BasicJson
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

      class NamespaceHALSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :namespace
          properties do |p|
            p.rdf_uri   item.uri
            p.name      item.prefLabel
            p.prefix    item.prefix
            p.type      item.type ? item.type.sub(VOCABULARY_RDF, '') : nil
          end

          link :self,     link_self(item.prefix)
        end

        private

        def link_self(id)
          {
            :type => :namespace,
            :href => "#{base_url}/api/namespaces/#{id}"
          }
        end
      end

      class NamespaceCollectionJsonSerializer < BaseSerializer
        adapter Oat::Adapters::BasicJson
        schema do
          type :'namespace-collection'
          entities :namespaces, item, NamespaceJsonSerializer
        end
      end

      class NamespaceCollectionHALSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'namespace-collection'
          entities :namespaces, item, NamespaceHALSerializer

          link :self,       link_self
          link :start,      link_start(item[0][:short_form])
        end

        private

        def link_self
          {
            :type => :'namespace-collection',
            :href => "#{base_url}/api/namespaces"
          }
        end
      end

      class NamespaceValueJsonSerializer < BaseSerializer
        adapter Oat::Adapters::BasicJson
        schema do
          type :'namespace-value'
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

      class NamespaceValueHALSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'namespace-value'
          parts = URI(item.uri).path.split('/')[3..-1]
          namespace_id = parts[0]
          namespace_value_id = parts.join('/')
          properties do |p|
            p.rdf_uri       item.uri
            p.type          item.type ? item.type.sub(VOCABULARY_RDF, '') : nil
            p.identifier    item.identifier
            p.title         item.title
            p.species       item.fromSpecies
            p.namespace_uri item.inScheme
          end

          link :self,       link_self(namespace_value_id)
          link :collection, link_namespace(namespace_id)
          link :item,       link_equivalents(namespace_value_id)
          link :item,       link_orthologs(namespace_value_id)
        end

        private

        def link_self(id)
          {
            :type => :'namespace-value',
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
            :type => :'namespace-value-collection',
            :href => "#{base_url}/api/namespaces/#{id}/equivalents"
          }
        end

        def link_orthologs(id)
          {
            :type => :'namespace-value-collection',
            :href => "#{base_url}/api/namespaces/#{id}/orthologs"
          }
        end
      end

      class NamespaceValueCollectionJsonSerializer < BaseSerializer
        adapter Oat::Adapters::BasicJson
        schema do
          type :'namespace-value-collection'
          entities :'namespace-values', item, NamespaceValueJsonSerializer
        end
      end

      class NamespaceValueCollectionHALSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'namespace-value-collection'
          entities :'namespace-values', item, NamespaceValueHALSerializer
        end
      end

      class ValueEquivalenceJsonSerializer < BaseSerializer
        adapter Oat::Adapters::BasicJson
        schema do
          type :'value-equivalence'
          properties do |p|
            p.value         item.value
            p.type          item.type ? item.type.sub(VOCABULARY_RDF, '') : nil
            p.identifier    item.identifier
            p.title         item.title
            p.species       item.fromSpecies
            p.namespace_uri item.inScheme
          end

          entities :equivalences, item.equivalences, NamespaceValueJsonSerializer
        end
      end

      class ValueEquivalenceHALSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :'value-equivalence'
          properties do |p|
            p.value         item.value
            p.type          item.type ? item.type.sub(VOCABULARY_RDF, '') : nil
            p.identifier    item.identifier
            p.title         item.title
            p.species       item.fromSpecies
            p.namespace_uri item.inScheme
          end

          entities :equivalences, item.equivalences, NamespaceValueHALSerializer
        end
      end
    end
  end
end
# vim: ts=2 sw=2
