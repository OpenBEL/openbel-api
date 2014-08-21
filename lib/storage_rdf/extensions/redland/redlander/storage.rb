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
      #object = options[:object_literal] ? literal_node(object) : uri_node(object)
      @model.statements.each(
        :subject => subject,
        :predicate => predicate,
        :object => object
      )
    end

    def all(statement)
      [
        statement.subject.value.to_s,
        statement.predicate.value.to_s,
        statement.object.value.to_s
      ]
    end

    def subject(statement)
      statement.subject.value.to_s
    end

    def predicate(statement)
      statement.predicate.value.to_s
    end

    def object(statement)
      statement.object.value.to_s
    end

    private

    def uri_node(obj)
      return URI(obj) if obj.is_a? String
      obj
    end

    # def literal_node(obj)
    #   Redland.librdf_new_node_from_typed_literal($world.world, obj.to_s, '', @xsd_type_uri)
    # end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
