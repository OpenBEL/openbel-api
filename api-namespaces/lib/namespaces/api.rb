require_relative 'model.rb'

module OpenBEL
  module Namespace
    module Storage

      NAMESPACE_PREFIX = 'http://www.openbel.org/bel/namespace/'

      def uri_for_namespace(name)
        NAMESPACE_PREFIX + name
      end

      def namespaces
        raise NotImplementedError
      end

      def namespace(id)
        raise NotImplementedError
      end

      def info(ns, id)
        # TODO Like SPARQL DESCRIBE
        raise NotImplementedError
      end

      def canonical(ns, id)
        raise NotImplementedError
      end

      def equivalences(ns, id)
        raise NotImplementedError
      end

      def namespace_equivalence(uri, namespace_uri)
        raise NotImplementedError
      end

      def orthologs(uri)
        raise NotImplementedError
      end

      def species_ortholog(uri, species)
        raise NotImplementedError
      end
    end

    class SqliteStorage
      include OpenBEL::Namespace::Storage

      def initialize(storage_name)
        require 'redlander'
        @model = Redlander::Model.new({
          storage: 'sqlite',
          name: storage_name,
          synchronous: 'off'
        })

        if block_given?
          yield @model
        end
      end

      def namespaces
        @model.statements.all({
          predicate: URI('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
          object: URI('http://www.openbel.org/vocabulary/NamespaceConceptScheme')
        }).map { |trpl|
          namespace_by_uri(trpl.subject.uri)
        }
      end

      # TODO Create a Namespace object that is enumerable over values.

      def namespace(id)
        Namespace.from_statements(@model.statements.all({
          subject: URI(NAMESPACE_PREFIX + id)
        }))
      end

      def info(ns, id)
        namespace_value_by_uri(URI(NAMESPACE_PREFIX + ns + '/' + id))
      end

      def canonical(ns, id)
        uri = NAMESPACE_PREFIX + ns + '/' + id
        query = "select subject_uri from temp.equivalences where object_uri = '#{uri}'"
        @db.execute(query).map{ |res| res.first }.map(&:to_s)
      end

      def equivalences(ns, id) 
        uri = NAMESPACE_PREFIX + ns + '/' + id
        @model.statements.all({
          subject: URI(uri),
          predicate: URI('http://www.w3.org/2004/02/skos/core#exactMatch')
        }).map { |trpl|
          namespace_value_by_uri(trpl.object.uri)
        }
      end

      def namespace_equivalence(ns, id, target)
        target_ns = URI(NAMESPACE_PREFIX + target)
        puts target_ns
        equivalences(ns, id).find { |nsv| nsv.inScheme == target_ns }
      end

      def orthologs(ns, id)
        uri = NAMESPACE_PREFIX + ns + '/' + id
        @model.statements.all({
          subject: URI(uri),
          predicate: URI('http://www.openbel.org/vocabulary/orthologousMatch')
        }).map { |trpl|
          namespace_value_by_uri(trpl.object.uri)
        }
      end

      def species_ortholog(uri, species)
        raise NotImplementedError
      end

      private
      def namespace_by_uri(uri)
        Namespace.from_statements(@model.statements.all({
          subject: uri
        }))
      end

      def namespace_value_by_uri(uri)
        NamespaceValue.from_statements(@model.statements.all({
          subject: uri
        }))
      end
    end
  end
end
# vim: ts=2 sw=2
