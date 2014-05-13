require_relative 'model.rb'
require 'uri'

module OpenBEL
  module Namespace
    class API

      def initialize(storage)
        @storage = storage
      end

      def find_namespaces(options = {})
        @storage.statements({
          predicate: URI('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
          object: URI('http://www.openbel.org/vocabulary/NamespaceConceptScheme')
        }).map { |statement|
          namespace_by_uri(statement.subject.uri)
        }
      end

      def find_namespace(namespace, options = {})
        # TODO namespace can also be prefix or prefLabel
        uri = case namespace
          when URI
            namespace
          when Namespace
            namespace.uri
          else
            URI(NAMESPACE_PREFIX + namespace.to_s)
          end
        namespace_by_uri(uri)
      end

      def find_namespace_value(namespace, value, options = {})
        value_uri = case value
          when URI
            value
          when NamespaceValue
            value.uri
          else
            URI(NAMESPACE_PREFIX + namespace + '/' + value)
          end
        namespace_value_by_uri(value_uri)
        # TODO namespace can be uri, prefix, prefLabel, or Namespace
        # TODO value can be concept identifier, prefLabel, or title
      end

      def find_equivalence(namespace, value, options = {})
        # TODO namespace can be uri, prefix, prefLabel, or Namespace
        # TODO value can be concept identifier, prefLabel, or title
        # TODO options[:target_namespace] can control target ns
        value_uri = case value
          when URI
            value
          when NamespaceValue
            value.uri
          else
            URI(NAMESPACE_PREFIX + namespace + '/' + value)
          end
        equivalences = @storage.statements({
          subject: URI(value_uri),
          predicate: URI('http://www.w3.org/2004/02/skos/core#exactMatch')
        })
        if options[:target]
          equivalences.find_all { |s|
            s.object.uri.to_s.include? options[:target]
          }.map { |s|
            namespace_value_by_uri(s.object.uri)
          }
        else
          equivalences.map { |s| namespace_value_by_uri(s.object.uri) }
        end
      end

      def find_orthology(namespace, value, options = {})
        # TODO namespace can be uri, prefix, prefLabel, or Namespace
        # TODO value can be concept identifier, prefLabel, or title
        # TODO options[:target_namespace] can control target ns
        value_uri = case value
          when URI
            value
          when NamespaceValue
            value.uri
          else
            URI(NAMESPACE_PREFIX + namespace + '/' + value)
          end
        orthology = @storage.statements({
          subject: URI(value_uri),
          predicate: URI('http://www.openbel.org/vocabulary/orthologousMatch')
        })
        if options[:target]
          orthology.find_all { |s|
            s.object.uri.to_s.include? options[:target]
          }.map { |s|
            namespace_value_by_uri(s.object.uri)
          }
        else
          orthology.map { |s| namespace_value_by_uri(s.object.uri) }
        end
      end

      private

      NAMESPACE_PREFIX = 'http://www.openbel.org/bel/namespace/'

      def find_namespace_rdf_uri(namespace)
        return nil unless namespace

        if namespace.is_a? OpenBEL::Model::Namespace
          namespace.uri
        else
          NAMESPACE_PREFIX
        end
      end

      def namespace_by_uri(uri)
        Namespace.from_statements(@storage.statements({
          subject: uri
        }))
      end

      def namespace_value_by_uri(uri)
        NamespaceValue.from_statements(@storage.statements({
          subject: uri
        }))
      end
    end
  end
end
# vim: ts=2 sw=2
