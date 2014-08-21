require 'rdf/redland'

module OpenBEL
  module LibRdfStorage
    class TripleIterator

      class << self
        def create_finalizer(librdf_stream)
          proc { Redland.librdf_free_stream(librdf_stream) }
        end
      end

      def initialize(librdf_stream, options = {})
        @librdf_stream = librdf_stream
        ObjectSpace.define_finalizer(self, TripleIterator.create_finalizer(@librdf_stream))
      end

      def each
        fail if not @librdf_stream
        if block_given?
          while not (Redland.librdf_stream_end(@librdf_stream) != 0)
            stmt = Redland.librdf_stream_get_object(@librdf_stream)
            s_node = Redland.librdf_statement_get_subject(stmt)
            p_node = Redland.librdf_statement_get_predicate(stmt)
            o_node = Redland.librdf_statement_get_object(stmt)
            yield [s_node, p_node, o_node]
            Redland.librdf_stream_next(@librdf_stream)
          end
        else
          enum_for(:each)
        end
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
