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

      ON_OPEN = [
        """create
          temp table equivalences
        as
          select
            US.uri as subject_uri, UO.uri as object_uri
          from
            uris U, uris US, uris UO, triples T
          where
            T.predicateUri = U.id and
            U.uri = 'http://www.w3.org/2004/02/skos/core#exactMatch' and
            US.id = T.subjectUri and UO.id = T.objectUri;""",
        'create index temp.sub_index on equivalences(subject_uri);',
        'create index temp.obj_index on equivalences(object_uri);'
      ]

      def initialize(storage_name)
        require 'redlander'
        require 'sqlite3'
        @model = Redlander::Model.new({
          storage: 'sqlite',
          name: storage_name,
          synchronous: 'off'
        })
        @proxy = Redlander::ModelProxy.new(@model)

        @db = SQLite3::Database.new storage_name
        ON_OPEN.each { |sql| @db.execute sql }

        if block_given?
          yield @model
        end
      end

      def namespaces
        @proxy.all({
          predicate: URI('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
          object: URI('http://www.openbel.org/vocabulary/NamespaceConceptScheme')
        }).map { |trpl|
          namespace_by_uri(trpl.subject.uri)
        }
      end

      # TODO Create a Namespace object that is enumerable over values.

      def namespace(id)
        Namespace.from_statements(@proxy.all({
          subject: URI(NAMESPACE_PREFIX + id)
        }))
      end

      def info(ns, id)
        NamespaceValue.from_statements(@proxy.all({
          subject: URI(NAMESPACE_PREFIX + ns + '/' + id)
        }))
      end

      def canonical(ns, id)
        uri = NAMESPACE_PREFIX + ns + '/' + id
        query = "select subject_uri from temp.equivalences where object_uri = '#{uri}'"
        @db.execute(query).map{ |res| res.first }.map(&:to_s)
      end

      def equivalences(ns, id) 
        uri = NAMESPACE_PREFIX + ns + '/' + id
        stmt = @db.prepare("""
          WITH RECURSIVE
            chain(subject_uri, object_uri) AS (
              SELECT E.* FROM temp.equivalences E WHERE subject_uri = ? or object_uri = ?
              UNION
              SELECT E.* FROM temp.equivalences E JOIN chain ON (E.subject_uri = chain.object_uri or E.object_uri = chain.subject_uri)
            )
          SELECT * from chain;
        """)
        stmt.bind_param 1, uri
        stmt.bind_param 2, uri
        stmt.execute.map{ |res| res.first }.map(&:to_s)
      end

      def namespace_equivalence(ns, id, target)
        uri = NAMESPACE_PREFIX + ns + '/' + id
        namespace_uri = NAMESPACE_PREFIX + target
        query = """
          WITH RECURSIVE
            chain_subject(subject_uri, object_uri) AS (
              SELECT E.object_uri, E.subject_uri FROM temp.equivalences E WHERE subject_uri = '#{uri}'
              UNION ALL
              SELECT E.subject_uri, E.object_uri FROM temp.equivalences E JOIN chain_subject ON E.object_uri = chain_subject.subject_uri
            ),
            chain_object(object_uri, subject_uri) AS (
              SELECT E.subject_uri, E.object_uri FROM temp.equivalences E WHERE object_uri = '#{uri}'
              UNION ALL
              SELECT E.object_uri, E.subject_uri FROM temp.equivalences E JOIN chain_object ON E.subject_uri = chain_object.object_uri
            )
          SELECT subject_uri FROM chain_subject WHERE subject_uri like '#{namespace_uri}/%' UNION
          SELECT object_uri FROM chain_object WHERE object_uri like '#{namespace_uri}/%'"""
        @db.execute(query).map(&:to_s)
      end

      def orthologs(uri)
        raise NotImplementedError
      end

      def species_ortholog(uri, species)
        raise NotImplementedError
      end

      private
      def namespace_by_uri(uri)
        Namespace.from_statements(@proxy.all({
          subject: uri
        }))
      end
    end
  end
end
# vim: ts=2 sw=2
