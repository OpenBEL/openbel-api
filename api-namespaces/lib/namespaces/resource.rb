require 'roar/decorator'
require 'roar/representer/json'
require 'representable/json/collection'

module OpenBEL
  module Namespace

    module NamespaceResourceJSON
      include Roar::Representer::JSON

      property :uri, as: :rdf_uri
      property :prefLabel, as: :name
      property :prefix
    end

    module NamespacesResourceJSON
      include Representable::JSON::Collection

      items extend: NamespaceResourceJSON, class: OpenBEL::Namespace::Namespace
    end
  end
end
# vim: ts=2 sw=2
