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

      # FIXME use cache
      def each_namespace_value(namespace, options = {}, &block)
        namespace = find_namespace_rdf_uri(namespace)
        @storage.statements(
          nil, SKOS_IN_SCHEME, namespace, nil
        ) do |subject, predicate, object|
          block.call namespace_value_by_uri(subject)
        end
      end

      def find_equivalent(namespace, value, options = {})
        matches = options[:target] ?
          @cache.fetch_target_equivalences(namespace, [value], options[:target]) :
          @cache.fetch_equivalences(namespace, [value])
        return nil if not matches or matches.empty?

        (_, equivalents) = matches.first
        equivalents.map { |entry|
          OpenBEL::Model::Namespace::NamespaceValue.new(
            :uri => entry[0],
            :identifier => entry[2],
            :prefLabel => entry[3],
            :title => entry[4]
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

      def find_ortholog(namespace, value, options = {})
        matches = options[:target] ?
          @cache.fetch_target_orthologs(namespace, [value], options[:target]) :
          @cache.fetch_orthologs(namespace, [value])
        return nil if not matches or matches.empty?

        (_, orthologs) = matches.first
        orthologs.map { |entry|
          OpenBEL::Model::Namespace::NamespaceValue.new(
            :uri => entry[0],
            :identifier => entry[2],
            :prefLabel => entry[3],
            :title => entry[4]
          )
        }
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
          orth_hash = @cache.fetch_target_orthologs(namespace, values, target)
          orth_hash.each { |key, value|
            next unless value
            orth_hash[key] = value.map { |v|
              map_fx.call(v)
            }
          }
          orth_hash
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

          orth_hash = @cache.fetch_orthologs(namespace, values)
          orth_hash.each { |key, value|
            next unless value
            orth_hash[key] = value.map { |v|
              map_fx.call(v)
            }
          }
          orth_hash
        end
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
