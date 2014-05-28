require_relative 'storage.rb'
require 'rdf'
require 'redlander'

class StorageRedlander
  include OpenBEL::Storage

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
      subject = hash[:subject]
      if subject
        hash[:subject] = to_redland(subject)
      end
      predicate = hash[:predicate]
      if predicate
        hash[:predicate] = to_redland(predicate)
      end
      object = hash[:object]
      if object
        hash[:object] = to_redland(object)
      end
      hash
    when RDF::Literal
      obj.to_s
    else
      node_ptr = Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, obj.to_s)
      Redlander::Node.new(node_ptr)
    end
  end

  def to_rdf(obj)
    return nil unless obj
    case obj
    when Redlander::Node
      if obj.literal?
        RDF::Literal(obj.value)
      elsif obj.resource?
        RDF::URI(obj.to_s[1..-2])
      end
    when Redlander::Statement
      subject = to_rdf(obj.subject)
      predicate = to_rdf(obj.predicate)
      object = to_rdf(obj.object)
      RDF::Statement.new(subject, predicate, object)
    end
  end
end
# vim: ts=2 sw=2
