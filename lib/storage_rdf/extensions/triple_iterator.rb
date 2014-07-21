require 'rdf/redland'

module OpenBEL
  class TripleIterator
    include Enumerable

    class << self

      def all(*args)
        subject = Redland.librdf_node_to_string(args.shift)[1..-2]
        predicate = Redland.librdf_node_to_string(args.shift)[1..-2]
        object = Redland.librdf_node_to_string(args.shift)
        if object[0] == '<'
          object = object[1..-2]
        else
          object = object[1..(object.index('^^') - 2)]
        end
        [subject, predicate, object]
      end

      def subject(*args)
        Redland.librdf_node_to_string(args.shift)[1..-2]
      end

      def predicate(*args)
        args.shift
        Redland.librdf_node_to_string(args.shift)[1..-2]
      end

      def object(*args)
        args.shift
        args.shift
        object = Redland.librdf_node_to_string(args.shift)
        if object[0] == '<'
          object = object[1..-2]
        else
          object = object[1..(object.index('^^') - 2)]
        end
      end

      def create_finalizer(librdf_stream)
        proc { Redland.librdf_free_stream(librdf_stream) }
      end
    end

    def initialize(librdf_stream, options = {})
      @librdf_stream = librdf_stream
      ObjectSpace.define_finalizer(self, TripleIterator.create_finalizer(@librdf_stream))

      @triple_map_method = case options[:only]
      when :subject
        TripleIterator.method(:subject)
      when :predicate
        TripleIterator.method(:predicate)
      when :object
        TripleIterator.method(:object)
      else
        TripleIterator.method(:all)
      end
    end

    def each
      fail if not @librdf_stream
      if block_given?
        while not stream_end?(@librdf_stream)
          stmt = stream_current_statement(@librdf_stream)
          s_node = Redland.librdf_statement_get_subject(stmt)
          p_node = Redland.librdf_statement_get_predicate(stmt)
          o_node = Redland.librdf_statement_get_object(stmt)
          yield @triple_map_method.call(s_node, p_node, o_node)
          stream_next(@librdf_stream)
        end
      else
        new_enum = enum_for(:each)
        new_enum.respond_to?(:lazy) ? new_enum.lazy : new_enum
      end
    end

    def stream_end?(librdf_stream)
      Redland.librdf_stream_end(librdf_stream) != 0
    end

    def stream_current_statement(librdf_stream)
      Redland.librdf_stream_get_object(librdf_stream)
    end

    def stream_next(librdf_stream)
      Redland.librdf_stream_next(librdf_stream)
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
