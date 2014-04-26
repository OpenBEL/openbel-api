require 'roar/decorator'
require 'roar/representer/json'
require 'representable/json/collection'

module OpenBEL
  module Namespace

    module NamespaceResource
      include Roar::Representer::JSON
      include OpenBEL::HTML

      property :uri, as: :rdf_uri
      property :prefLabel, as: :name
      property :prefix
    end

    module NamespacesResource
      include Representable::JSON::Collection
      include OpenBEL::HTML

      items extend: NamespaceResource, class: OpenBEL::Namespace::Namespace
    end
  end
end
# vim: ts=2 sw=2
