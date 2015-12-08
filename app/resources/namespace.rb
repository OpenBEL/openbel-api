require_relative 'base'

module OpenBEL
  module Resource
    module Namespaces

      VOCABULARY_RDF = 'http://www.openbel.org/vocabulary/'

      class NamespaceValueSearchResult < BEL::Resource::NamespaceValue

        def match_text=(match_text)
          @match_text = match_text
        end

        def match_text
          @match_text
        end
      end

      class NamespaceSerializer < BaseSerializer
#        adapter Oat::Adapters::HAL
        schema do
          type     :namespace
          property :rdf_uri, item.uri.to_s
          property :name,    item.prefLabel
          property :prefix,  item.prefix
          property :domain,  item.domain
        end
      end

      class NamespaceResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type     :namespace
          property :namespace,  item
          link     :self,       link_self(item)
          link     :collection, link_collection
        end

        private

        def link_self(item)
          {
            :type => :namespace,
            :href => "#{base_url}/api/namespaces/#{item[:prefix]}"
          }
        end

        def link_collection
          {
            :type => :namespace_collection,
            :href => "#{base_url}/api/namespaces"
          }
        end
      end

      class NamespaceCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type     :namespace_collection
          property :namespace_collection, item
          link     :self,                 link_self
          link     :start,                link_start
        end

        private

        def link_self
          {
            :type => :namespace_collection,
            :href => "#{base_url}/api/namespaces"
          }
        end

        def link_start
          {
            :type => :start,
            :href => "#{base_url}/api/namespaces/values"
          }
        end
      end

      class NamespaceValueSerializer < BaseSerializer
        #adapter Oat::Adapters::HAL
        schema do
          type     :namespace_value
          property :rdf_uri,       item.uri.to_s
          property :type,          [item.type].flatten.map(&:to_s)
          property :identifier,    item.identifier
          property :name,          item.prefLabel
          property :title,         item.title
          property :species,       item.fromSpecies
          entity   :namespace,     item.namespace, NamespaceSerializer

          # Support inclusion of the matched text when annotation values are filtered by
          # a full-text search.
          if item.match_text
            property :match_text,    item.match_text
          end
        end
      end

      class NamespaceValueResourceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          parts = URI(item.delete(:rdf_uri)).path.split('/')[3..-1]
          namespace_id = parts[0]
          namespace_value_id = parts.join('/')

          type     :namespace_value
          property :namespace_value, item
          link     :self,            link_self(namespace_value_id)
          link     :collection,      link_namespace(namespace_id)
          link     :equivalents,     link_equivalents(namespace_value_id)
          link     :orthologs,       link_orthologs(namespace_value_id)
        end

        private

        def link_self(id)
          {
            :type => :namespace_value,
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
            :type => :namespace_value_collection,
            :href => "#{base_url}/api/namespaces/#{id}/equivalents"
          }
        end

        def link_orthologs(id)
          {
            :type => :namespace_value_collection,
            :href => "#{base_url}/api/namespaces/#{id}/orthologs"
          }
        end
      end

      class NamespaceValueCollectionSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type     :namespace_value_collection
          property :namespace_value_collection, item
        end
      end

      class ValueEquivalenceSerializer < BaseSerializer
        adapter Oat::Adapters::HAL
        schema do
          type :value_equivalence
          property :value,         item.value
          property :type,          item.type ? item.type.sub(VOCABULARY_RDF, '') : nil
          property :identifier,    item.identifier
          property :title,         item.title
          property :species,       item.fromSpecies
          property :namespace_uri, item.inScheme

          property :value_equivalence_collection, item.equivalences, NamespaceValueSerializer
        end
      end
    end
  end
end
# vim: ts=2 sw=2
