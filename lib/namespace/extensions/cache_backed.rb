require_relative '../namespace_api'
require_relative '../model'
require 'benchmark'

module OpenBEL
  module Namespace
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
        @cache = options[:cache]
        unless @cache
          fail ArgumentError, "cache not provided in options"
        end
      end

      def find_namespaces(options = {})
        @cache.fetch_namespaces.map { |ns_array|
          OpenBEL::Model::Namespace::Namespace.new(
            :uri => ns_array[0],
            :prefix => ns_array[2],
            :prefLabel => ns_array[3],
            :type => ns_array[4]
          )
        }
      end

      def find_namespace(namespace, options = {})
        match = @cache.fetch_namespace(namespace)
        return nil unless match

        OpenBEL::Model::Namespace::Namespace.new(
          :uri => match[0],
          :prefix => match[2],
          :prefLabel => match[3],
          :type => match[4]
        )
      end

      def find_namespace_value(namespace, value, options = {})
        match = @cache.fetch_values(namespace, value)
        return nil unless match

        OpenBEL::Model::Namespace::NamespaceValue.new(
          :uri => match[0],
          :identifier => match[1],
          :prefLabel => match[2],
          :title => match[3]
        )
      end

      def each_namespace_value(namespace, options = {}, &block)
        namespace = find_namespace_rdf_uri(namespace)
        @storage.statements(
          nil, SKOS_IN_SCHEME, namespace, nil
        ) do |subject, predicate, object|
          block.call namespace_value_by_uri(subject)
        end
      end

      def find_equivalent(namespace, value, options = {})
        if options[:target]
          match = @cache.fetch_target_equivalences(namespace, value, options[:target])
          return nil unless match

          return OpenBEL::Model::Namespace::NamespaceValue.new(
            :uri => match[0],
            :identifier => match[1],
            :prefLabel => match[2],
            :title => match[3]
          )
        end

        matches = @cache.fetch_equivalences(namespace, value)
        return nil if not matches or matches.empty?

        matches.map { |entry|
          OpenBEL::Model::Namespace::NamespaceValue.new(
            :uri => entry[0],
            :identifier => entry[1],
            :prefLabel => entry[2],
            :title => entry[3]
          )
        }
      end

      def find_equivalents(namespace, values, options = {})
        options = {result: :resource}.merge options

        if options[:target]
          map_fx =
            case options[:result]
            when :identifier
              lambda { |v| v[2] }
            when :prefLabel
              lambda { |v| v[3] }
            when :title
              lambda { |v| v[4] }
            else
              lambda { |v|
                OpenBEL::Model::Namespace::NamespaceValue.new(
                  :uri => v[1],
                  :inScheme => v[0],
                  :identifier => v[2],
                  :prefLabel => v[3],
                  :title => v[4]
                ).to_hash
              }
            end

          target = options[:target]
          eq_hash = @cache.fetch_target_equivalences(namespace, values, target)
          eq_hash.each { |key, value|
            next unless value
            eq_hash[key] = value.map { |v|
              map_fx.call(v)
            }
          }
        else
          map_fx =
            case options[:result]
            when :identifier
              lambda { |v| { 'uri' => v[0], 'identifier' => v[2] } }
            when :prefLabel
              lambda { |v| { 'uri' => v[0], 'prefLabel' => v[3] } }
            when :title
              lambda { |v| { 'uri' => v[0], 'title' => v[4] } }
            else
              lambda { |v|
                OpenBEL::Model::Namespace::NamespaceValue.new(
                  :uri => v[0],
                  :inScheme => v[1],
                  :identifier => v[2],
                  :prefLabel => v[3],
                  :title => v[4]
                ).to_hash
              }
            end

          eq_hash = @cache.fetch_equivalences(namespace, values)
          eq_hash.each { |key, value|
            next unless value
            eq_hash[key] = value.map { |v|
              map_fx.call(v)
            }
          }
          eq_hash
        end
      end

      def find_orthologs(namespace, values, options = {})
        options = {result: :resource}.merge options

        if options[:target]
          map_fx =
            case options[:result]
            when :identifier
              lambda { |v| v[2] }
            when :prefLabel
              lambda { |v| v[3] }
            when :title
              lambda { |v| v[4] }
            else
              lambda { |v|
                OpenBEL::Model::Namespace::NamespaceValue.new(
                  :uri => v[1],
                  :inScheme => v[0],
                  :identifier => v[2],
                  :prefLabel => v[3],
                  :title => v[4]
                ).to_hash
              }
            end

          target = options[:target]
          eq_hash = @cache.fetch_target_orthologs(namespace, values, target)
          eq_hash.each { |key, value|
            next unless value
            eq_hash[key] = value.map { |v|
              map_fx.call(v)
            }
          }
        else
          map_fx =
            case options[:result]
            when :identifier
              lambda { |v| { 'uri' => v[0], 'identifier' => v[2] } }
            when :prefLabel
              lambda { |v| { 'uri' => v[0], 'prefLabel' => v[3] } }
            when :title
              lambda { |v| { 'uri' => v[0], 'title' => v[4] } }
            else
              lambda { |v|
                OpenBEL::Model::Namespace::NamespaceValue.new(
                  :uri => v[0],
                  :inScheme => v[1],
                  :identifier => v[2],
                  :prefLabel => v[3],
                  :title => v[4]
                ).to_hash
              }
            end

          eq_hash = @cache.fetch_orthologs(namespace, values)
          eq_hash.each { |key, value|
            next unless value
            eq_hash[key] = value.map { |v|
              map_fx.call(v)
            }
          }
          eq_hash
        end
      end

      private

      NAMESPACE_PREFIX = 'http://www.openbel.org/bel/namespace/'

      def find_namespace_rdf_uri(namespace)
        return nil unless namespace
        ns = @cache.fetch_namespace(namespace)
        ns ? ns[0] : nil
      end

      def find_namespace_value_rdf_uri(namespace, value)
        return nil unless value

        case value
        when OpenBEL::Namespace::NamespaceValue
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
        ns_uri = nil
        @storage.statements(
          nil, SKOS_PREF_LABEL, nil, label
        ) do |sub, pred, obj|
          if sub.start_with? namespace_uri
            ns_uri = sub
            break
          end
        end
        ns_uri
      end

      def namespace_value_by_identifier(namespace_uri, id)
        ns_uri = nil
        @storage.statements(
          nil, DC_IDENTIFIER, nil, id
        ) do |sub, pred, obj|
          if sub.start_with? namespace_uri
            ns_uri = sub
            break
          end
        end
        ns_uri
      end

      def namespace_value_by_title(namespace_uri, title)
        ns_uri = nil
        @storage.statements(
          nil, DC_TITLE, nil, title
        ) do |sub, pred, obj|
          if sub.start_with? namespace_uri
            ns_uri = sub
            break
          end
        end
        ns_uri
      end

      def namespace_value_by_uri(uri)
        value_statements = []
        @storage.statements(uri, nil, nil, nil) do |sub, pred, obj|
          value_statements << [sub, pred, obj]
        end
        NamespaceValue.from(value_statements)
      end

      def namespace_value_with_result(uri, result)
        case result
        when :name
          @storage.statements(
            uri, SKOS_PREF_LABEL
          ) do |sub, pred, obj|
            return obj
            #return NamespaceValue.new({uri: uri, prefLabel: obj})
          end
        when :identifier
          @storage.statements(
            uri, DC_IDENTIFIER
          ) do |sub, pred, obj|
            return obj
            #return NamespaceValue.new({uri: uri, identifier: obj})
          end
        when :title
          @storage.statements(
            uri, DC_TITLE
          ) do |sub, pred, obj|
            return obj
            #return NamespaceValue.new({uri: uri, title: obj})
          end
        else
          namespace_value_by_uri(uri)
        end
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
