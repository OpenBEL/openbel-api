require_relative 'storage.rb'
require 'redlander'
require 'uri'

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

    unless pattern.respond_to? :to_hash
      fail ArgumentError, "pattern expected to respond to 'to_hash'"
    end
    hash = pattern.to_hash
    if block_given?
      @model.statements.each(hash, &block)
    else
      @model.statements.all(hash)
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
