require_relative 'storage.rb'
require 'rdf/redland' #redland bindings

class StorageLibrdf
  include OpenBEL::Storage

  STREAM_ACTIVE = 0

  def initialize(options = {})
    cfg = DEFAULTS.merge(options)
    $world = Redland::World.new
    @model = Redland::Model.new(Redland::TripleStore.new(cfg[:storage], cfg[:name], "synchronous=off"))

    # pre-allocate
    @xsd_type_uri = Redland.librdf_new_uri($world.world, 'http://www.w3.org/2001/XMLSchema#string')
  end

  def describe(subject, &block)
    return nil unless subject
    statements({ subject: subject }, &block)
  end

  def statements(sub = nil, pred = nil, o_uri = nil, o_literal = nil, &block)
    begin
      s_node = uri_node(sub)
      p_node = uri_node(pred)
      if o_uri
        o_node = uri_node(o_uri)
      elsif o_literal
        o_node = literal_node(o_literal)
      else
        o_node = nil
      end

      find(s_node, p_node, o_node) do |sub, pred, obj|
        s_uri = Redland.librdf_node_to_string(sub)[1..-2]
        p_uri = Redland.librdf_node_to_string(pred)[1..-2]
        o_val = Redland.librdf_node_to_string(obj)
        if o_val[0] == '<'
          o_val = o_val[1..-2]
        else
          o_val = o_val[1..(o_val.index('^^') - 2)]
        end
        block.call s_uri, p_uri, o_val
      end
    ensure
      if s_node
        Redland::librdf_free_node(s_node)
      end
      if p_node
        Redland::librdf_free_node(p_node)
      end
      if o_node
        Redland::librdf_free_node(o_node)
      end
    end
  end

  private

  DEFAULTS = {
    storage: 'sqlite',
    name: 'rdf.db',
    synchronous: 'off'
  }

  def uri_node(obj)
    Redland.librdf_new_node_from_uri_string($world.world, obj.to_s)
  end

  def literal_node(obj)
    Redland.librdf_new_node_from_typed_literal($world.world, obj.to_s, '', @xsd_type_uri)
  end

  def find(s, p, o)
    begin
      librdf_statement = Redland.librdf_new_statement_from_nodes($world.world, s, p, o)
      librdf_stream = Redland.librdf_model_find_statements(@model.model, librdf_statement)
      return nil if not librdf_stream

      while not stream_end?(librdf_stream)
        stmt = stream_current_statement(librdf_stream)
        s_node = Redland.librdf_statement_get_subject(stmt)
        p_node = Redland.librdf_statement_get_predicate(stmt)
        o_node = Redland.librdf_statement_get_object(stmt)
        yield s_node, p_node, o_node
        stream_next(librdf_stream)
      end
    ensure
      #Redland::librdf_free_statement(librdf_statement)
      Redland::librdf_free_stream(librdf_stream)
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
# vim: ts=2 sw=2
