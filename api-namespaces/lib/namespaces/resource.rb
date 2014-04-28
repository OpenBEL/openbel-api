require 'roar/decorator'
require 'roar/representer/json'
require 'representable/json/collection'

module OpenBEL
  module Namespace

    VOCABULARY_RDF = 'http://www.openbel.org/vocabulary/'

    module NamespaceResource
      include OpenBEL::HTML
      include Roar::Representer::JSON
      include Roar::Representer::Feature::Hypermedia

      property :uri, as: :rdf_uri
      property :prefLabel, as: :name
      property :prefix
      property :type, :getter => lambda { |opts|
        type.sub(VOCABULARY_RDF, '')
      }

      link :self do |opts|
        resource_name = uri[uri.rindex('/')+1..-1]
        "#{opts[:base_url]}/namespaces/#{resource_name}"
      end
    end

    module NamespacesResource
      include Representable::JSON::Collection
      include OpenBEL::HTML

      items extend: NamespaceResource, class: OpenBEL::Namespace::Namespace
    end

    module NamespaceValueResource
      include OpenBEL::HTML
      include Roar::Representer::JSON
      include Roar::Representer::Feature::Hypermedia

      property :uri, as: :rdf_uri
      property :type, :getter => lambda { |opts|
        type.sub(VOCABULARY_RDF, '')
      }
      property :identifier
      property :prefLabel, as: :name
      property :title
      property :fromSpecies, as: :species
      property :inScheme, as: :namespace_uri

      link :self do |opts|
        parts = URI(uri).path.split('/')[3..-1]
        "#{opts[:base_url]}/namespaces/#{parts.join('/')}"
      end
      link :parent do |opts|
        parts = URI(uri).path.split('/')[3...-1]
        "#{opts[:base_url]}/namespaces/#{parts.join('/')}"
      end
      link(rel: :subresource, type: 'equivalence') do |opts|
        parts = URI(uri).path.split('/')[3..-1]
        "#{opts[:base_url]}/namespaces/#{parts.join('/')}/equivalences"
      end
    end

    module NamespaceValuesResource
      include Representable::JSON::Collection
      include OpenBEL::HTML

      items extend: NamespaceValueResource, class: OpenBEL::Namespace::NamespaceValue
    end
  end
end
# vim: ts=2 sw=2
