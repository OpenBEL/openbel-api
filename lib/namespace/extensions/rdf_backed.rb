require_relative '../namespace_api'
require_relative '../model'

module OpenBEL
  module Namespace

    # XXX Methods that return multiple elements are buffered to Arrays. I chose this
    # approach over leaking Enumerator::Lazy to namespace resource layer.
    class Namespace
      include NamespaceAPI

      SKOS_PREF_LABEL = 'http://www.w3.org/2004/02/skos/core#prefLabel'
      SKOS_EXACT_MATCH = 'http://www.w3.org/2004/02/skos/core#exactMatch'
      SKOS_IN_SCHEME = 'http://www.w3.org/2004/02/skos/core#inScheme'
      DC_IDENTIFIER = 'http://purl.org/dc/terms/identifier'
      DC_TITLE = 'http://purl.org/dc/terms/title'
      BEL_PREFIX = 'http://www.openbel.org/vocabulary/prefix'
      BEL_NAMESPACE_CONCEPT_SCHEME = 'http://www.openbel.org/vocabulary/NamespaceConceptScheme'
      BEL_ORTHOLOGOUS_MATCH = 'http://www.openbel.org/vocabulary/orthologousMatch'
      RDF_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'

      attr_reader :storage

      def initialize(options = {})
        @storage = options[:storage]
        unless @storage
          fail ArgumentError, "storage not provided in options"
        end
      end

      def find_namespaces(options = {})
        @storage.triples(
          nil, RDF_TYPE, BEL_NAMESPACE_CONCEPT_SCHEME, :only => :subject
        ).map { |concept|
          namespace_by_uri(concept)
        }.to_a
      end

      def find_namespace(namespace, options = {})
        namespace_uri = find_namespace_rdf_uri(namespace)
        return nil unless namespace_uri

        namespace_by_uri(namespace_uri)
      end

      def find_namespace_value(namespace, value, options = {})
        value_uri = find_namespace_value_rdf_uri(namespace, value)
        return nil unless value_uri

        namespace_value_by_uri(value_uri)
      end

      def find_namespace_values(namespace, options = {})
        namespace = find_namespace_rdf_uri(namespace)
        values = @storage.triples(
          nil, SKOS_IN_SCHEME, namespace, :only => :subject
        ).drop((options[:offset] || 0).to_i)
        values = values.take(options[:size]) if options[:size]
        result_func = result_function(options[:result])

        if block_given?
          values.each do |subject|
            yield result_func.call(subject)
          end
        else
          values.map { |subject|
            result_func.call(subject)
          }.to_a
        end
      end

      # TODO Refactor into reusable namespace value query + targetted (see find_ortholog)
      def find_equivalent(namespace, value, options = {})
        if value.is_a? OpenBEL::Model::Namespace::NamespaceValue
          value_uri = value.uri
        else
          value_uri = find_namespace_value_rdf_uri(namespace, value)
        end
        return nil unless value_uri

        if options[:target]
          target_uri = find_namespace_rdf_uri(options[:target])
          return nil unless target_uri

          @storage.triples(
            value_uri, SKOS_EXACT_MATCH, nil, :only => :object
          ).find_all { |object|
            object.start_with? target_uri
          }.map { |object|
            namespace_value_by_uri(object)
          }.to_a
        else
          @storage.triples(
            value_uri, SKOS_EXACT_MATCH, nil, :only => :object
          ).map { |object|
            namespace_value_by_uri(object)
          }.to_a
        end
      end

      # TODO Refactor into reusable namespace value query + targetted (see find_orthologs)
      def find_equivalents(namespace, values, options = {})
        options = {result: :resource}.merge options
        namespace_uri = find_namespace_rdf_uri(namespace).to_s
        result_func = result_function(options[:result])

        if options[:target]
          target_uri = find_namespace_rdf_uri(options[:target])
          return nil unless target_uri

          values.inject({}) { |hash, item|
            item_key = item.to_s
            concept_uri = namespace_value_by_pref_label(namespace_uri, item_key)
            unless concept_uri
              hash[item_key] = nil
            else
              hash[item_key] = @storage.triples(
                concept_uri, SKOS_EXACT_MATCH, nil, :only => :object
              ).find_all { |object|
                object.start_with? target_uri
              }.map { |object|
                result_func.call(object)
              }.to_a
            end
            hash
          }
        else
          values.inject({}) { |hash, item|
            item_key = item.to_s
            concept_uri = namespace_value_by_pref_label(namespace_uri, item_key)
            unless concept_uri
              hash[item_key] = nil
            else
              hash[item_key] = @storage.triples(
                concept_uri, SKOS_EXACT_MATCH, nil, :only => :object
              ).map { |object|
                result_func.call(object)
              }.to_a
            end
            hash
          }
        end
      end

      # TODO Refactor into reusable namespace value query + targetted (see find_equivalent)
      def find_ortholog(namespace, value, options = {})
        if value.is_a? OpenBEL::Model::Namespace::NamespaceValue
          value_uri = value.uri
        else
          value_uri = find_namespace_value_rdf_uri(namespace, value)
        end
        return nil unless value_uri

        if options[:target]
          target_uri = find_namespace_rdf_uri(options[:target])
          return nil unless target_uri

          @storage.triples(
            value_uri, BEL_ORTHOLOGOUS_MATCH, nil, :only => :object
          ).find_all { |object|
            object.start_with? target_uri
          }.map { |object|
            namespace_value_by_uri(object)
          }.to_a
        else
          @storage.triples(
            value_uri, BEL_ORTHOLOGOUS_MATCH, nil, :only => :object
          ).map { |object|
            namespace_value_by_uri(object)
          }.to_a
        end
      end

      # TODO Refactor into reusable namespace value query + targetted (see find_equivalents)
      def find_orthologs(namespace, values, options = {})
        options = {result: :resource}.merge options
        namespace_uri = find_namespace_rdf_uri(namespace).to_s
        result_func = result_function(options[:result])

        if options[:target]
          target_uri = find_namespace_rdf_uri(options[:target])
          return nil unless target_uri

          values.inject({}) { |hash, item|
            item_key = item.to_s
            concept_uri = namespace_value_by_pref_label(namespace_uri, item_key)
            unless concept_uri
              hash[item_key] = nil
            else
              hash[item_key] = @storage.triples(
                concept_uri, BEL_ORTHOLOGOUS_MATCH, nil, :only => :object
              ).find_all { |object|
                object.start_with? target_uri
              }.map { |object|
                result_func.call(object)
              }.to_a
            end
            hash
          }
        else
          values.inject({}) { |hash, item|
            item_key = item.to_s
            concept_uri = namespace_value_by_pref_label(namespace_uri, item_key)
            unless concept_uri
              hash[item_key] = nil
            else
              hash[item_key] = @storage.triples(
                concept_uri, BEL_ORTHOLOGOUS_MATCH, nil, :only => :object
              ).map { |object|
                result_func.call(object)
              }.to_a
            end
            hash
          }
        end
      end

      private

      NAMESPACE_PREFIX = 'http://www.openbel.org/bel/namespace/'

      def find_namespace_rdf_uri(namespace)
        return nil unless namespace

        if namespace.is_a? Symbol
          namespace = namespace.to_s
        end

        case namespace
        when OpenBEL::Model::Namespace::Namespace
          namespace.uri
        when String
          [
            self.method(:namespace_by_prefix),
            self.method(:namespace_by_pref_label),
            self.method(:namespace_by_uri_part)
          ].each do |m|
            uri = m.call(namespace)
            return uri if uri
          end
        end
      end

      def find_namespace_value_rdf_uri(namespace, value)
        return nil unless value

        case value
        when OpenBEL::Model::Namespace::NamespaceValue
          value.uri
        when URI
          value
        when String
          namespace_uri = find_namespace_rdf_uri(namespace)
          [
            self.method(:namespace_value_by_pref_label),
            self.method(:namespace_value_by_identifier),
            self.method(:namespace_value_by_title)
          ].each do |m|
            uri = m.call(namespace_uri, value)
            return uri if uri
          end
        end
      end

      def namespace_value_by_pref_label(namespace_uri, label)
        @storage.triples(
          nil, SKOS_PREF_LABEL, label, :object_literal => true, :only => :subject
        ).find { |subject|
          subject.start_with? namespace_uri
        }
      end

      def namespace_value_by_identifier(namespace_uri, id)
        @storage.triples(
          nil, DC_IDENTIFIER, id, :object_literal => true, :only => :subject
        ).find { |subject|
          subject.start_with? namespace_uri
        }
      end

      def namespace_value_by_title(namespace_uri, title)
        @storage.triples(
          nil, DC_TITLE, title, :object_literal => true, :only => :subject
        ).find { |subject|
          subject.start_with? namespace_uri
        }
      end

      def namespace_by_prefix(prefix)
        @storage.triples(
          nil, BEL_PREFIX, prefix, :object_literal => true, :only => :subject
        ).first
      end

      def namespace_by_pref_label(label)
        @storage.triples(
          nil, SKOS_PREF_LABEL, label, :object_literal => true, :only => :subject
        ).first
      end

      def namespace_by_uri_part(label)
        NAMESPACE_PREFIX + URI.encode(label)
      end

      def namespace_by_uri(uri)
        OpenBEL::Model::Namespace::Namespace.from(
          @storage.triples(uri, nil, nil).to_a
        )
      end

      def namespace_value_by_uri(uri)
        OpenBEL::Model::Namespace::NamespaceValue.from(
          @storage.triples(uri, nil, nil).to_a
        )
      end

      def result_function(result)
        case result
        when :prefLabel
          lambda { |value_uri|
            @storage.triples(
              value_uri, SKOS_PREF_LABEL, nil, :only => :object
            ).first
          }
        when :identifier
          lambda { |value_uri|
            @storage.triples(
              value_uri, DC_IDENTIFIER, nil, :only => :object
            ).first
          }
        when :title
          lambda { |value_uri|
            @storage.triples(
              value_uri, DC_TITLE, nil, :only => :object
            ).first
          }
        else
          self.method(:namespace_value_by_uri)
        end
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
