require 'redlander'
require_relative 'storage'

module OpenBEL::Storage

  class Redlander
    include Storage

    def initialize(options = {})
      options = Hash[options.map {|k,v| [k.to_sym, v]}]
      @model_options = DEFAULTS.merge(options)
    end

    def triples(subject, predicate, object, options={})
      model = (Thread.current[:model] ||= Redlander::Model.new @model_options)

      map_method = options[:only]
      if map_method && self.respond_to?(map_method)
        map_method = self.method(map_method)
      end
      map_method ||= self.method(:all)

      triples = model.statements.each(
        :subject => uri_node(subject),
        :predicate => uri_node(predicate),
        :object => options[:object_literal] ? literal_node(object) : uri_node(object)
      )
      if block_given?
        triples.each { |triple| yield map_method.call(triple) }
      else
        triples = triples.respond_to?(:lazy) ? triples.lazy : triples
        triples.map(&map_method)
      end
    end

    private

    def all(statement)
      if statement.respond_to? :subject
        [
          statement.subject.to_s[1..-2],
          statement.predicate.to_s[1..-2],
          statement.object.to_s[1..-2]
        ]
      else
        statement
      end
    end

    def subject(statement)
      return statement.subject.to_s[1..-2] if statement.respond_to? :subject
      statement[0]
    end

    def predicate(statement)
      return statement.predicate.to_s[1..-2] if statement.respond_to? :predicate
      statement[1]
    end

    def object(statement)
      return statement.object.value if statement.respond_to? :object
      statement[2]
    end

    def uri_node(obj)
      return nil unless obj
      Redlander::Node.new(obj.to_s, :resource => true)
    end

    def literal_node(object)
      Redlander::Node.new(object.to_s)
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
