require_relative 'model.rb'
require 'set'
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
        namespace_uri = find_namespace_rdf_uri(namespace)
        return nil unless namespace_uri

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

      def find_equivalents(namespace, values, options = {})
        vset = Set.new(values)

        namespace_uri = find_namespace_rdf_uri(namespace).to_s
        if options[:target]
          target_namespace = find_namespace_rdf_uri(options[:target]).to_s
          vset.map { |v|
            pref = @storage.statements({
              predicate: URI('http://www.w3.org/2004/02/skos/core#prefLabel'),
              object: v.to_s
            }).find { |statement|
              statement.subject.uri.to_s.include? namespace_uri
            }

            if pref
              matches = @storage.statements({
                subject: pref.subject,
                predicate: URI('http://www.w3.org/2004/02/skos/core#exactMatch')
              }).find_all { |statement|
                statement.object.uri.to_s.include? target_namespace
              }
              if matches
                target_equivalences = matches.map { |match|
                  eq_pref = @storage.statements({
                    subject: match.object,
                    predicate: URI('http://www.w3.org/2004/02/skos/core#prefLabel'),
                  }).first
                  eq_pref ? eq_pref.object.value : nil
                }.find_all.to_a
                [v, target_equivalences.empty? ? nil : target_equivalences]
              else
                [v, nil]
              end
            else
              [v, nil]
            end
          }.to_h
        else
          vset.map { |v|
            pref = @storage.statements({
              predicate: URI('http://www.w3.org/2004/02/skos/core#prefLabel'),
              object: v.to_s
            }).find { |statement|
              statement.subject.uri.to_s.include? namespace_uri
            }

            if pref
              matches = @storage.statements({
                subject: pref.subject,
                predicate: URI('http://www.w3.org/2004/02/skos/core#exactMatch')
              }).map { |statement|
                statement.object
              }
              if matches
                all_equivalences = matches.map { |match|
                  eq_pref = @storage.statements({
                    subject: match,
                    predicate: URI('http://www.w3.org/2004/02/skos/core#prefLabel'),
                  }).first
                  eq_pref ? eq_pref.object.value : nil
                }.find_all.to_a
                [v, all_equivalences.empty? ? nil : all_equivalences]
              else
                [v, nil]
              end
            else
              [v, nil]
            end
          }.to_h
        end
      end

      def find_orthologs(namespace, value, options = {})
        value_uri = find_namespace_value_rdf_uri(namespace, value)
        return nil unless value_uri

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
          
          pref_statement = @storage.statements({
            predicate: URI('http://www.w3.org/2004/02/skos/core#prefLabel'),
            object: value
          }).find { |statement|
            statement.subject.uri.to_s.start_with? namespace_uri.to_s
          }
          pref_statement ? pref_statement.subject.uri : nil
        end
      end

      def namespace_value_by_pref_label(namespace_uri, label)
        pref_statement = @storage.statements({
          predicate: URI('http://www.w3.org/2004/02/skos/core#prefLabel'),
          object: label
        }).find { |statement|
          statement.subject.uri.to_s.start_with? namespace_uri.to_s
        }
        pref_statement ? pref_statement.subject.uri : nil
      end

      def namespace_value_by_identifier(namespace_uri, id)
        id_statement = @storage.statements({
          predicate: URI('http://purl.org/dc/terms/identifier'),
          object: id
        }).find { |statement|
          statement.subject.uri.to_s.start_with? namespace_uri.to_s
        }
        id_statement ? id_statement.subject.uri : nil
      end

      def namespace_value_by_title(namespace_uri, title)
        title_statement = @storage.statements({
          predicate: URI('http://purl.org/dc/terms/title'),
          object: title
        }).find { |statement|
          statement.subject.uri.to_s.start_with? namespace_uri.to_s
        }
        title_statement ? title_statement.subject.uri : nil
      end

      def namespace_by_prefix(prefix)
        @storage.statements({
          predicate: URI('http://www.openbel.org/vocabulary/prefix'),
          object: prefix
        }).map { |statement| statement.subject.uri }.first
      end

      def namespace_by_pref_label(label)
        @storage.statements({
          predicate: URI('http://www.w3.org/2004/02/skos/core#prefLabel'),
          object: label
        }).map { |statement| statement.subject.uri }.first
      end

      def namespace_by_uri_part(label)
        URI(NAMESPACE_PREFIX + URI.encode(label))
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
