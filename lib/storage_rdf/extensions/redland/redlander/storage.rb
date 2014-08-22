require 'uri'
require 'redlander'

module OpenBEL
  module RedlanderStorage

    def model(options = {})
      @model = Redlander::Model.new options
    end

    def statement_enumerator(subject, predicate, object, options = {})
      subject = uri_node(subject)
      predicate = uri_node(predicate)
      @model.statements.each(
        :subject => subject,
        :predicate => predicate,
        :object => object
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
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
