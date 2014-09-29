require 'uri'
require 'redlander'

module OpenBEL
  module RedlanderStorage

    XSD_TYPE_URI = Redland.librdf_new_uri(Redlander.rdf_world, 'http://www.w3.org/2001/XMLSchema#string')

    def model(options = {})
      Redlander::Model.new options
    end

    def statement_enumerator(model, subject, predicate, object, options = {})
      model.statements.each(
        :subject => uri_node(subject),
        :predicate => uri_node(predicate),
        :object => options[:object_literal] ? literal_node(object) : uri_node(object)
      )
    end

    def all(statement)
      [
        statement.subject.to_s[1..-2],
        statement.predicate.to_s[1..-2],
        statement.object.to_s[1..-2]
      ]
    end

    def subject(statement)
      statement.subject.to_s[1..-2]
    end

    def predicate(statement)
      statement.predicate.to_s[1..-2]
    end

    def object(statement)
      statement.object.to_s[1..-2]
    end

    private

    def uri_node(obj)
      return nil unless obj
      Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, obj.to_s)
      #Redlander::Node.new(obj.to_s, :resource => true)
    end

    def literal_node(object)
      #Redlander::Node.new(object.to_s)
      Redland.librdf_new_node_from_typed_literal(Redlander.rdf_world, object.to_s, '', XSD_TYPE_URI)
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
