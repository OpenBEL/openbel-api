require_relative 'model.rb'
require_relative 'vocab.rb'
require 'gdbm'

module OpenBEL
  module Namespace
    class API

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

      def initialize(storage)
        @storage = storage
        @dbe = GDBM.new('equiv_table_fk.db', 0666, GDBM::READER)
      end

      def find_namespaces(options = {})
        namespaces = []
        @storage.statements(
          nil, RDF_TYPE, BEL_NAMESPACE_CONCEPT_SCHEME
        ) do |sub, pred, obj|
          namespaces << namespace_by_uri(sub)
        end
        return namespaces
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

      def each_namespace_value(namespace, options = {}, &block)
        namespace = find_namespace_rdf_uri(namespace)
        @storage.statements(
          nil, SKOS_IN_SCHEME, namespace, nil
        ) do |subject, predicate, object|
          block.call namespace_value_by_uri(subject)
        end
      end

      def find_equivalent(namespace, value, options = {})
        if value.is_a? OpenBEL::Namespace::NamespaceValue
          value_uri = value.uri
        else
          value_uri = find_namespace_value_rdf_uri(namespace, value)
        end
        return nil unless value_uri

        if options[:target]
          target_uri = find_namespace_rdf_uri(options[:target])
          target_ns = namespace_by_uri(target_uri)
          unless target_ns
            return nil
          end
          matches = []
          @storage.statements(
            value_uri, SKOS_EXACT_MATCH
          ) do |sub, pred, obj|
            if obj.start_with? target_ns.uri
              matches << namespace_value_by_uri(obj)
            end
          end
          return matches
        end

        equivalences = []
        @storage.statements(
          value_uri, SKOS_EXACT_MATCH
        ) do |sub, pred, obj|
          equivalences << namespace_value_by_uri(obj)
        end
        equivalences
      end

      def find_equivalents(namespace, values, options = {})
        options = {result: :resource}.merge options
        namespace_uri = find_namespace_rdf_uri(namespace).to_s

        if options[:target]
          target_namespace = find_namespace_rdf_uri(options[:target]).to_s

          values.map { |v|
            val = @dbe["#{namespace_uri}:#{v}:#{target_namespace}"]
            if not val
              [v, nil]
            else
              #prefLabel
              [v, val.unpack('m*')[0].split('\0')[1]]
            end
          }.to_h

          #values.map { |v|
            #pref = nil
            #@storage.statements(
              #nil, SKOS_PREF_LABEL, nil, v.to_s
            #) do |sub, pred, obj|
              #if sub.include? namespace_uri
                #pref = sub
                #break
              #end
            #end

            #if pref
              #matches = []
              #@storage.statements(
                #pref, SKOS_EXACT_MATCH
              #) do |sub, pred, obj|
                #if obj.include? target_namespace
                  #matches << obj
                #end
              #end

              #if matches
                #target_equivalences = matches.map { |match|
                  #namespace_value_with_result(match, options[:result])
                #}
                #ValueEquivalence.new(v.to_s, target_equivalences)
              #else
                #ValueEquivalence.new(v.to_s, nil)
              #end
            #else
              #ValueEquivalence.new(v.to_s, nil)
            #end
          #}
        else
          values.map { |v|
            pref = nil
            @storage.statements(
              nil, SKOS_PREF_LABEL, nil, v.to_s
            ) do |sub, pred, obj|
              if sub.include? namespace_uri
                pref = sub
                break
              end
            end

            if pref
              matches = []
              @storage.statements(
                pref, SKOS_EXACT_MATCH
              ) do |sub, pred, obj|
                matches << obj
              end

              if matches
                all_equivalences = matches.map { |match|
                  namespace_value_with_result(match, options[:result])
                }
                ValueEquivalence.new(v.to_s, all_equivalences)
              else
                ValueEquivalence.new(v.to_s, nil)
              end
            else
              ValueEquivalence.new(v.to_s, nil)
            end
          }
        end
      end

      def find_orthologs(namespace, value, options = {})
        if value.is_a? OpenBEL::Namespace::NamespaceValue
          value_uri = value.uri
        else
          value_uri = find_namespace_value_rdf_uri(namespace, value)
        end
        return nil unless value_uri

        if options[:target]
          target_uri = find_namespace_rdf_uri(options[:target])
          target_ns = namespace_by_uri(target_uri)
          unless target_ns
            return nil
          end
          matches = []
          @storage.statements(
            value_uri, BEL_ORTHOLOGOUS_MATCH
          ) do |sub, pred, obj|
            if obj.start_with? target_ns.uri
              matches << namespace_value_by_uri(obj)
            end
          end
          return matches
        end

        orthologs = []
        @storage.statements(
          value_uri, BEL_ORTHOLOGOUS_MATCH
        ) do |sub, pred, obj|
          orthologs << namespace_value_by_uri(obj)
        end
        orthologs
      end

      private

      NAMESPACE_PREFIX = 'http://www.openbel.org/bel/namespace/'

      def find_namespace_rdf_uri(namespace)
        return nil unless namespace

        if namespace.is_a? Symbol
          namespace = namespace.to_s
        end

        case namespace
        when OpenBEL::Namespace::Namespace
          namespace.uri
        when RDF::URI
          namespace
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

      def namespace_by_prefix(prefix)
        @storage.statements(
          nil, BEL_PREFIX, nil, prefix
        ) do |sub, pred, obj|
          return sub
        end
      end

      def namespace_by_pref_label(label)
        @storage.statements(
          nil, SKOS_PREF_LABEL, nil, label
        ) do |sub, pred, obj|
          return sub
        end
      end

      def namespace_by_uri_part(label)
        NAMESPACE_PREFIX + URI.encode(label)
      end

      def namespace_by_uri(uri)
        ns_stmts = []
        @storage.statements(uri) do |sub, pred, obj|
          ns_stmts << [sub, pred, obj]
        end
        Namespace.from(ns_stmts)
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
# vim: ts=2 sw=2
