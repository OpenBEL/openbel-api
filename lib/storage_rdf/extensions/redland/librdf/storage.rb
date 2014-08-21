require 'rdf/redland'
require_relative 'triple_iterator.rb'

module OpenBEL
  module LibRdfStorage

    XML_SCHEMA_STRING = 'http://www.w3.org/2001/XMLSchema#string'

    def model(options = {})
      $world_ptr = Redland::World.new.world
      @xsd_type_uri = Redland.librdf_new_uri($world_ptr, XML_SCHEMA_STRING)
      storage_type = options.delete(:storage)
      name = options.delete(:name)
      extra_options = options.map { |k,v| "#{k}=#{v}" }.join(',')
      @model = Redland::Model.new(
        Redland::TripleStore.new(storage_type, name, extra_options)
      )
    end

    def statement_enumerator(subject, predicate, object, options = {})
      subject = uri_node(subject)
      predicate = uri_node(predicate)
      object = options[:object_literal] ? literal_node(object) : uri_node(object)
      librdf_stream = create_stream(subject, predicate, object)
      OpenBEL::LibRdfStorage::TripleIterator.new(librdf_stream, options).each
    end

    def all(statement_array)
      subject = Redland.librdf_node_to_string(statement_array.shift)[1..-2]
      predicate = Redland.librdf_node_to_string(statement_array.shift)[1..-2]
      object = Redland.librdf_node_to_string(statement_array.shift)
      if object[0] == '<'
        object = object[1..-2]
      else
        object = object[1..(object.index('^^') - 2)]
      end
      [subject, predicate, object]
    end

    def subject(statement_array)
      Redland.librdf_node_to_string(statement_array.shift)[1..-2]
    end

    def predicate(statement_array)
      statement_array.shift
      Redland.librdf_node_to_string(statement_array.shift)[1..-2]
    end

    def object(statement_array)
      statement_array.shift
      statement_array.shift
      object = Redland.librdf_node_to_string(statement_array.shift)
      if object[0] == '<'
        object = object[1..-2]
      else
        object = object[1..(object.index('^^') - 2)]
      end
    end

    private

    def uri_node(object)
      Redland.librdf_new_node_from_uri_string($world_ptr, object.to_s)
    end

    def literal_node(object)
      Redland.librdf_new_node_from_typed_literal($world_ptr, object.to_s, '', @xsd_type_uri)
    end

    def create_stream(subject, predicate, object)
      librdf_statement = Redland.librdf_new_statement_from_nodes($world_ptr, subject, predicate, object)
      Redland.librdf_model_find_statements(@model.model, librdf_statement)
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
