require_relative 'storage.rb'
require 'rdf'
require 'redlander'
require 'pry'

class StorageRedlander
  include OpenBEL::Storage

  attr_accessor :model

  def initialize(options = {})
    storage_configuration = DEFAULTS.merge(options)
    @model = Redlander::Model.new(storage_configuration)
  end

  def describe(subject, &block)
    return nil unless subject
    pattern = {
      subject: URI(subject.to_s)
    }
    statements(pattern, &block)
  end

  def statements(pattern, &block)
    return nil unless pattern
    spo = to_redland(pattern)
    if block_given?
      @model.statements.each(spo) do |obj|
        block.call to_rdf(obj)
      end
    else
      @model.statements.each(spo).map { |obj| to_rdf(obj) }
    end
  end

  private

  DEFAULTS = {
    storage: 'sqlite',
    name: 'rdf.db',
    synchronous: 'off'
  }

  def to_redland(obj)
    return nil unless obj

    case obj
    when RDF::Statement
      unless obj.respond_to? :to_hash
        fail ArgumentError, "obj expected to respond to 'to_hash'"
      end
      hash = obj.to_hash
      sub = hash[:subject]
      if sub
        sub = Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, sub.to_s)
      end
      pred = hash[:predicate]
      if pred
        pred = Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, pred.to_s)
      end
      obj = hash[:object]
      if obj
        case obj
        when RDF::URI
          obj = Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, obj.to_s)
        when RDF::Literal
          type_uri = Redland.librdf_new_uri(Redlander.rdf_world, obj.datatype.to_s)
          obj = Redland.librdf_new_node_from_typed_literal(Redlander.rdf_world, obj.to_s, nil, type_uri)
        else
          obj = Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, obj.to_s)
        end
      end
      Redlander::Statement.new(
        Redland.librdf_new_statement_from_nodes(Redlander.rdf_world, sub, pred, obj)
      )
    when RDF::Literal
      type_uri = Redland.librdf_new_uri(Redlander.rdf_world, obj.datatype.to_s)
      Redlander::Node.new(
        Redland.librdf_new_node_from_typed_literal(Redlander.rdf_world, obj.to_s, nil, type_uri)
      )
    else
      node_ptr = Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, obj.to_s)
      Redlander::Node.new(node_ptr)
    end
  end

  def to_rdf(obj)
    return nil unless obj
    stmt_ptr = obj.rdf_statement

    sptr = Redland.librdf_statement_get_subject(stmt_ptr)
    uri = Redland.librdf_node_to_string(sptr)
    subject = RDF::URI(uri.to_s[1..-2])

    pptr = Redland.librdf_statement_get_predicate(stmt_ptr)
    uri = Redland.librdf_node_to_string(pptr)
    predicate = RDF::URI(uri.to_s[1..-2])

    optr = Redland.librdf_statement_get_object(stmt_ptr)
    if Redland.librdf_node_is_literal(optr) != 0
      value = Redland.librdf_node_get_literal_value(optr).force_encoding("UTF-8")
      object = RDF::Literal(value)
    elsif Redland.librdf_node_is_resource(optr) != 0
      uri = Redland.librdf_node_to_string(optr)
      object = RDF::URI(uri.to_s[1..-2])
    end

    RDF::Statement.new(subject, predicate, object)
  end
end
# vim: ts=2 sw=2
