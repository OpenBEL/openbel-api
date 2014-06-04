require_relative 'storage.rb'
require 'rdf/redland'

class StorageLibrdf
  include OpenBEL::Storage
  include Redland

  def initialize(options = {})
    cfg = DEFAULTS.merge(options)
    $world = World.new
    @model = Model.new(TripleStore.new(cfg[:storage], cfg[:name], "synchronous=off"))
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

    unless pattern.respond_to? :to_hash
      fail ArgumentError, "pattern expected to respond to 'to_hash'"
    end
    if block_given?
      @model.find(Uri.new(pattern[:subject]), Uri.new(pattern[:predicate]), pattern[:object], nil, &block)
    else
      @model.find(pattern[:subject], pattern[:predicate], pattern[:object], nil)
    end
  end

  private

  DEFAULTS = {
    storage: 'sqlite',
    name: 'rdf.db',
    synchronous: 'off'
  }
end
# vim: ts=2 sw=2
