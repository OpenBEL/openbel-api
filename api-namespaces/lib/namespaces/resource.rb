require 'roar/decorator'
require 'roar/representer/json'
require 'representable/json/collection'

module OpenBEL
  module Namespace

    module NamespaceResource
      include OpenBEL::HTML
      include Roar::Representer::JSON
      include Roar::Representer::Feature::Hypermedia

      property :uri, as: :rdf_uri
      property :prefLabel, as: :name
      property :prefix

      link :self do |opts|
        "#{opts[:base_url]}/namespaces/#{prefLabel}"
      end
    end

    module NamespacesResource
      include Representable::JSON::Collection
      include OpenBEL::HTML

      items extend: NamespaceResource, class: OpenBEL::Namespace::Namespace
    end
  end
end
# vim: ts=2 sw=2
