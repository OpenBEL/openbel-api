require_relative '../api.rb'
require 'rdf/redland'
require_relative './triple_iterator.rb'

module OpenBEL
  class Storage
    include OpenBEL::StorageAPI

    DEFAULTS = {
      storage: 'sqlite',
      name: 'rdf.db',
      synchronous: 'off'
    }

    def initialize(options = {})
      option_symbols = Hash[options.map {|k,v| [k.to_sym, v]}]
      cfg = DEFAULTS.merge(option_symbols)
      $world = Redland::World.new
      @model = Redland::Model.new(Redland::TripleStore.new(cfg[:storage], cfg[:name], "synchronous=off"))

      # pre-allocate
      @xsd_type_uri = Redland.librdf_new_uri($world.world, 'http://www.w3.org/2001/XMLSchema#string')
    end

    def triples(subject, predicate, object, options={})
      subject = uri_node(subject)
      predicate = uri_node(predicate)
      object = options[:object_literal] ? literal_node(object) : uri_node(object)
      librdf_stream = create_stream(subject, predicate, object)
      OpenBEL::TripleIterator.new librdf_stream, options
    end

    private

    def uri_node(obj)
      Redland.librdf_new_node_from_uri_string($world.world, obj.to_s)
    end

    def literal_node(obj)
      Redland.librdf_new_node_from_typed_literal($world.world, obj.to_s, '', @xsd_type_uri)
    end

    def create_stream(s, p, o)
      librdf_statement = Redland.librdf_new_statement_from_nodes($world.world, s, p, o)
      Redland.librdf_model_find_statements(@model.model, librdf_statement)
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
