require_relative 'model.rb'
require_relative 'vocab.rb'
require 'rdf'
require 'set'

module OpenBEL
  module Namespace
    class API

      def initialize(storage)
        @storage = storage
      end

      def find_namespaces(options = {})
        @storage.statements(
          pattern(nil, RDF.type, BELVocabulary.NamespaceConceptScheme)
        ).map { |statement|
          namespace_by_uri(statement.subject)
        }
      end

      def find_namespace(namespace, options = {})
        namespace_uri = find_namespace_rdf_uri(namespace)
        return nil unless namespace_uri

        puts namespace_uri.class
        puts namespace_uri.to_s
        namespace_by_uri(namespace_uri)
      end

      def find_namespace_value(namespace, value, options = {})
        value_uri = find_namespace_value_rdf_uri(namespace, value)
        return nil unless value_uri

        namespace_value_by_uri(value_uri)
      end

      def find_equivalent(namespace, value, options = {})
        value_uri = find_namespace_value_rdf_uri(namespace, value)
        return nil unless value_uri

        # TODO value_uri needs to be an RDF::Resource
        equivalences = @storage.statements(
          pattern(value_uri, RDF::SKOS.exactMatch, nil)
        )
        if options[:target]
          equivalences.find_all { |s|
            s.object.to_s.include? options[:target]
          }.map { |s|
            namespace_value_by_uri(s.object)
          }
        else
          equivalences.map { |s| namespace_value_by_uri(s.object) }
        end
      end

      def find_equivalents(namespace, values, options = {})
        options = {result: :resource}.merge options
        vset = Set.new(values)

        namespace_uri = find_namespace_rdf_uri(namespace).to_s
        if options[:target]
          target_namespace = find_namespace_rdf_uri(options[:target]).to_s
          vset.map { |v|
            pref = @storage.statements(
              pattern(nil, RDF::SKOS.prefLabel, v.to_s)
            ).find { |statement|
              statement.subject.to_s.include? namespace_uri
            }

            if pref
              matches = @storage.statements(
                pattern(pref.subject, RDF::SKOS.exactMatch, nil)
              ).find_all { |statement|
                statement.object.to_s.include? target_namespace
              }.map { |statement| statement.object }
              if matches
                target_equivalences = matches.map { |match|
                  namespace_value_with_result(match, options[:result])
                }
                ValueEquivalence.new(v.to_s, target_equivalences)
              else
                ValueEquivalence.new(v.to_s, nil)
              end
            else
              ValueEquivalence.new(v.to_s, nil)
            end
          }
        else
          vset.map { |v|
            pref = @storage.statements(
              pattern(nil, RDF::SKOS.prefLabel, v.to_s)
            ).find { |statement|
              statement.subject.to_s.include? namespace_uri
            }

            if pref
              matches = @storage.statements(
                pattern(pref.subject, RDF::SKOS.exactMatch, nil)
              ).map { |statement|
                statement.object
              }
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
        value_uri = find_namespace_value_rdf_uri(namespace, value)
        return nil unless value_uri

        orthology = @storage.statements(
          pattern(value_uri, BELVocabulary.orthologousMatch, nil)
        )
        if options[:target]
          orthology.find_all { |s|
            s.object.to_s.include? options[:target]
          }.map { |s|
            namespace_value_by_uri(s.object)
          }
        else
          orthology.map { |s| namespace_value_by_uri(s.object) }
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
        when OpenBEL::Namespace::Namespace
          namespace.uri
        when URI
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
          
          pref_statement = @storage.statements(
            pattern(nil, RDF::SKOS.prefLabel, value)
          ).find { |statement|
            statement.subject.to_s.start_with? namespace_uri.to_s
          }
          pref_statement ? pref_statement.subject : nil
        end
      end

      def namespace_value_by_pref_label(namespace_uri, label)
        pref_statement = @storage.statements(
          pattern(nil, RDF::SKOS.prefLabel, label)
        ).find { |statement|
          statement.subject.to_s.start_with? namespace_uri.to_s
        }
        pref_statement ? pref_statement.subject : nil
      end

      def namespace_value_by_identifier(namespace_uri, id)
        id_statement = @storage.statements(
          pattern(nil, RDF::DC.identifier, id)
        ).find { |statement|
          statement.subject.to_s.start_with? namespace_uri.to_s
        }
        id_statement ? id_statement.subject : nil
      end

      def namespace_value_by_title(namespace_uri, title)
        title_statement = @storage.statements(
          pattern(nil, RDF::DC.title, title)
        ).find { |statement|
          statement.subject.to_s.start_with? namespace_uri.to_s
        }
        title_statement ? title_statement.subject : nil
      end

      def namespace_by_prefix(prefix)
        @storage.statements(
          pattern(nil, BELVocabulary.prefix, prefix)
        ).map { |statement| statement.subject }.first
      end

      def namespace_by_pref_label(label)
        @storage.statements(
          pattern(nil, RDF::SKOS.prefLabel, label)
        ).map { |statement| statement.subject }.first
      end

      def namespace_by_uri_part(label)
        RDF::URI(NAMESPACE_PREFIX + URI.encode(label))
      end

      def namespace_by_uri(uri)
        Namespace.from(@storage.statements(pattern(uri, nil, nil)))
      end

      def namespace_value_by_uri(uri)
        NamespaceValue.from(@storage.statements(pattern(uri, nil, nil)))
      end

      def namespace_value_with_result(uri, result)
        case result
        when :name
          @storage.statements(
            pattern(uri, RDF::SKOS.prefLabel, nil)
          ).map { |statement|
            label = statement.object.to_s
            NamespaceValue.new({uri: uri, prefLabel: label})
          }.first
        when :identifier
          @storage.statements(
            pattern(uri, RDF::DC.identifier, nil)
          ).map { |statement|
            identifier = statement.object.to_s
            NamespaceValue.new({uri: uri, identifier: identifier})
          }.first
        when :title
          @storage.statements(
            pattern(uri, RDF::DC.title, nil)
          ).map { |statement|
            title = statement.object.to_s
            NamespaceValue.new({uri: uri, title: title})
          }.first
        else
          namespace_value_by_uri(uri)
        end
      end

      def pattern(*args)
        @cache ||= {}
        @cache[args] ||= RDF::Statement.from(args)
      end
    end
  end
end
# vim: ts=2 sw=2
