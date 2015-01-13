require 'roar/decorator'
require 'roar/json'
require 'roar/xml'
require 'representable/json/collection'

module OpenBEL
  module Namespace

    VOCABULARY_RDF = 'http://www.openbel.org/vocabulary/'

    def self.resource_for(obj, content_type)
      if obj.respond_to? :each
        if not obj or obj.empty?
          return nil
        end

        # tests first object
        case obj.first
        when OpenBEL::Model::Namespace::Namespace
          case content_type
          when 'application/json'
            obj.extend(NamespacesResourceJSON)
          when 'text/html'
            obj.extend(NamespacesResourceHTML)
          when 'text/xml'
            obj.extend(NamespacesResourceXML)
          end
        when OpenBEL::Model::Namespace::NamespaceValue
          case content_type
          when 'application/json'
            obj.extend(NamespaceValuesResourceJSON)
          when 'text/html'
            obj.extend(NamespaceValuesResourceHTML)
          when 'text/xml'
            obj.extend(NamespaceValuesResourceXML)
          end
        when OpenBEL::Model::Namespace::ValueEquivalence
          case content_type
          when 'application/json'
            obj.extend(ValueEquivalencesResourceJSON)
          when 'text/html'
            obj.extend(ValueEquivalencesResourceHTML)
          when 'text/xml'
            obj.extend(ValueEquivalencesResourceXML)
          end
        else
          fail NotImplementedError, "Cannot make resource from #{obj.class}."
        end
      else
        case obj
        when OpenBEL::Model::Namespace::Namespace
          case content_type
          when 'application/json'
            obj.extend(NamespaceResourceJSON)
          when 'text/html'
            obj.extend(NamespaceResourceHTML)
          when 'text/xml'
            obj.extend(NamespaceResourceXML)
          end
        when OpenBEL::Model::Namespace::NamespaceValue
          case content_type
          when 'application/json'
            obj.extend(NamespaceValueResourceJSON)
          when 'text/html'
            obj.extend(NamespaceValueResourceHTML)
          when 'text/xml'
            obj.extend(NamespaceValueResourceXML)
          end
        when OpenBEL::Model::Namespace::ValueEquivalence
          case content_type
          when 'application/json'
            obj.extend(ValueEquivalenceResourceJSON)
          when 'text/html'
            obj.extend(ValueEquivalenceResourceHTML)
          when 'text/xml'
            obj.extend(ValueEquivalenceResourceXML)
          end
        else
          fail NotImplementedError, "Cannot make resource from #{obj.class}."
        end
      end
    end

    # NamespaceResource
    module NamespaceResourceJSON
      include Roar::JSON
      include Roar::Hypermedia

      property :uri, as: :rdf_uri
      property :prefLabel, as: :name
      property :prefix
      property :type, :getter => lambda { |opts|
        type ? type.sub(VOCABULARY_RDF, '') : nil
      }

      link :self do |opts|
        resource_name = uri[uri.rindex('/')+1..-1]
        "#{opts[:base_url]}/namespaces/#{resource_name}"
      end
    end

    module NamespaceResourceXML
      include Roar::XML
      include Roar::Hypermedia

      property :uri, as: :rdf_uri
      property :prefLabel, as: :name
      property :prefix
      property :type, :getter => lambda { |opts|
        type ? type.sub(VOCABULARY_RDF, '') : nil
      }

      link :self do |opts|
        resource_name = uri[uri.rindex('/')+1..-1]
        "#{opts[:base_url]}/namespaces/#{resource_name}"
      end
    end

    module NamespaceResourceHTML
      include Roar::JSON
      include OpenBEL::HTML
      include Roar::Hypermedia

      property :uri, as: :rdf_uri
      property :prefLabel, as: :name
      property :prefix
      property :type, :getter => lambda { |opts|
        type ? type.sub(VOCABULARY_RDF, '') : nil
      }

      link :self do |opts|
        resource_name = uri[uri.rindex('/')+1..-1]
        "#{opts[:base_url]}/namespaces/#{resource_name}"
      end
    end
    # -----

    # NamespacesResource
    module NamespacesResourceJSON
      include Representable::JSON::Collection
      items extend: NamespaceResourceJSON, class: OpenBEL::Model::Namespace
    end

    module NamespacesResourceXML
      include Representable::JSON::Collection
      include Roar::XML
      items extend: NamespaceResourceXML, class: OpenBEL::Model::Namespace
    end

    module NamespacesResourceHTML
      include Representable::JSON::Collection
      include OpenBEL::HTML
      items extend: NamespaceResourceHTML, class: OpenBEL::Model::Namespace
    end
    # -----

    # NamespaceValueResource
    module NamespaceValueResourceJSON
      include Roar::JSON
      include Roar::Hypermedia

      property :uri, as: :rdf_uri
      property :type, :getter => lambda { |opts|
        type ? type.sub(VOCABULARY_RDF, '') : nil
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
      link(:rel => :equivalents) do |opts|
        parts = URI(uri).path.split('/')[3..-1]
        "#{opts[:base_url]}/namespaces/#{parts.join('/')}/equivalents"
      end
      link(:rel => :orthology) do |opts|
        parts = URI(uri).path.split('/')[3..-1]
        "#{opts[:base_url]}/namespaces/#{parts.join('/')}/orthologs"
      end
    end

    module NamespaceValueResourceXML
      include Roar::XML
      include Roar::Hypermedia

      property :uri, as: :rdf_uri
      property :type, :getter => lambda { |opts|
        type ? type.sub(VOCABULARY_RDF, '') : nil
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
      link(:rel => :equivalents) do |opts|
        parts = URI(uri).path.split('/')[3..-1]
        "#{opts[:base_url]}/namespaces/#{parts.join('/')}/equivalents"
      end
      link(:rel => :orthology) do |opts|
        parts = URI(uri).path.split('/')[3..-1]
        "#{opts[:base_url]}/namespaces/#{parts.join('/')}/orthologs"
      end
    end

    module NamespaceValueResourceHTML
      include Roar::JSON
      include OpenBEL::HTML
      include Roar::Hypermedia

      property :uri, as: :rdf_uri
      property :type, :getter => lambda { |opts|
        type ? type.sub(VOCABULARY_RDF, '') : nil
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
      link(:rel => :equivalents) do |opts|
        parts = URI(uri).path.split('/')[3..-1]
        "#{opts[:base_url]}/namespaces/#{parts.join('/')}/equivalents"
      end
      link(:rel => :orthology) do |opts|
        parts = URI(uri).path.split('/')[3..-1]
        "#{opts[:base_url]}/namespaces/#{parts.join('/')}/orthologs"
      end
    end
    # -----

    # NamespaceValueResource
    module NamespaceValuesResourceJSON
      include Representable::JSON::Collection
      items extend: NamespaceValueResourceJSON, class: OpenBEL::Model::Namespace::NamespaceValue
    end

    module NamespaceValuesResourceXML
      include Representable::JSON::Collection
      include Roar::XML
      items extend: NamespaceValueResourceXML, class: OpenBEL::Model::Namespace::NamespaceValue
    end

    module NamespaceValuesResourceHTML
      include Representable::JSON::Collection
      include OpenBEL::HTML
      items extend: NamespaceValueResourceHTML, class: OpenBEL::Model::Namespace::NamespaceValue
    end
    # -----

    # ValueEquivalenceResource
    module ValueEquivalenceResourceJSON
      include Roar::JSON
      include Roar::Hypermedia

      property :value
      collection :equivalences,
        extend: NamespaceValueResourceJSON,
        class: OpenBEL::Model::Namespace::NamespaceValue
    end

    module ValueEquivalenceResourceXML
      include Roar::XML
      include Roar::Hypermedia

      property :value
      collection :equivalences,
        extend: NamespaceValueResourceXML,
        class: OpenBEL::Model::Namespace::NamespaceValue
    end

    module ValueEquivalenceResourceHTML
      include Roar::JSON
      include OpenBEL::HTML
      include Roar::Hypermedia

      property :value
      collection :equivalences,
        extend: NamespaceValueResourceHTML,
        class: OpenBEL::Model::Namespace::NamespaceValue
    end

    # ValueEquivalencesResource
    module ValueEquivalencesResourceJSON
      include Representable::JSON::Collection
      items extend: ValueEquivalenceResourceJSON, class: OpenBEL::Model::Namespace::ValueEquivalence
    end

    module ValueEquivalencesResourceXML
      include Representable::JSON::Collection
      include Roar::XML
      items extend: ValueEquivalenceResourceXML, class: OpenBEL::Model::Namespace::ValueEquivalence
    end

    module ValueEquivalencesResourceHTML
      include Representable::JSON::Collection
      include OpenBEL::HTML
      items extend: ValueEquivalenceResourceHTML, class: OpenBEL::Model::Namespace::ValueEquivalence
    end
    # -----

  end
end
# vim: ts=2 sw=2
