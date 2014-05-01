require_relative 'model.rb'
require 'pry'

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
        """create temp table equivalence as
           select
             US.id as subject_id, UO.id as object_id
           from
             uris U, uris US, uris UO, triples T
           where
             T.predicateUri = U.id and
             U.uri = 'http://www.w3.org/2004/02/skos/core#exactMatch' and
             US.id = T.subjectUri and UO.id = T.objectUri;""",
        'create index temp.equivalence_sub_index on equivalence(subject_id);',
        'create index temp.equivalence_obj_index on equivalence(object_id);',
        """create temp table orthology as
           select
              US.id as subject_id, UO.id as object_id
            from
              uris U, uris US, uris UO, triples T
            where
              T.predicateUri = U.id and
              U.uri = 'http://www.openbel.org/vocabulary/orthologousMatch' and
              US.id = T.subjectUri and UO.id = T.objectUri;""",
        'create index temp.orthology_sub_index on orthology(subject_id);',
        'create index temp.orthology_obj_index on orthology(object_id);',
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
        namespace_value_by_uri(URI(NAMESPACE_PREFIX + ns + '/' + id))
      end

      def canonical(ns, id)
        uri = NAMESPACE_PREFIX + ns + '/' + id
        query = "select subject_uri from temp.equivalences where object_uri = '#{uri}'"
        @db.execute(query).map{ |res| res.first }.map(&:to_s)
      end

      def equivalences(ns, id) 
        uri = NAMESPACE_PREFIX + ns + '/' + id
        begin
          value_query = @db.prepare('select id from uris where uri = ?')
          value_query.bind_param 1, uri
          value_id = value_query.execute.first[0]
        ensure
          value_query.close if value_query
        end
        return nil unless value_id

        begin
          eq_query = @db.prepare("""
            WITH RECURSIVE
              chain(subject_id, object_id) AS (
                SELECT E.* FROM temp.equivalence E WHERE subject_id = ? or object_id = ?
                UNION
                SELECT E.* FROM temp.equivalence E JOIN chain ON (
                  E.subject_id = chain.subject_id or
                  E.object_id = chain.object_id or
                  E.subject_id = chain.object_id or
                  E.object_id = chain.subject_id
                )
              )
            SELECT * from chain;
          """)
          eq_query.bind_param 1, value_id
          eq_query.bind_param 2, value_id
          eq_ids = eq_query.execute.map { |res| res }.flatten.uniq.find_all { |x| x != value_id }
          eq_ids.map { |eq_id|
            uri_by_id(eq_id)
          }.map { |eq_uri|
            namespace_value_by_uri(URI(eq_uri))
          }
        ensure
          eq_query.close if eq_query
        end
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

      def orthologs(ns, id)
        uri = NAMESPACE_PREFIX + ns + '/' + id
        begin
          value_query = @db.prepare('select id from uris where uri = ?')
          value_query.bind_param 1, uri
          value_id = value_query.execute.first[0]
        ensure
          value_query.close if value_query
        end
        return nil unless value_id

        begin
          ortho_query = @db.prepare("""
            WITH RECURSIVE
              chain(subject_id, object_id) AS (
                SELECT E.* FROM temp.orthology E WHERE subject_id = ? or object_id = ?
                UNION
                SELECT E.* FROM temp.orthology E JOIN chain ON (
                  E.subject_id = chain.subject_id or
                  E.object_id = chain.object_id or
                  E.subject_id = chain.object_id or
                  E.object_id = chain.subject_id
                )
              )
            SELECT * from chain;
          """)
          ortho_query.bind_param 1, value_id
          ortho_query.bind_param 2, value_id
          ortho_ids = ortho_query.execute.map { |res| res }.flatten.uniq.find_all { |x| x != value_id }
          binding.pry
          ortho_ids.map { |ortho_id|
            uri_by_id(ortho_id)
          }.map { |ortho_uri|
            namespace_value_by_uri(URI(ortho_uri))
          }
        ensure
          ortho_query.close if ortho_query
        end
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

      def namespace_value_by_uri(uri)
        NamespaceValue.from_statements(@proxy.all({
          subject: uri
        }))
      end

      def uri_by_id(id)
        begin
          uri_query = @db.prepare('select uri from uris where id = ?')
          uri_query.bind_param 1, id
          uri_query.execute.first[0]
        ensure
          uri_query.close if uri_query
        end
      end
    end
  end
end
# vim: ts=2 sw=2
