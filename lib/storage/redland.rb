require 'redlander'
require_relative 'triple_storage'

module OpenBEL::Storage

  class StorageRedland
    include TripleStorage

    def initialize(options = {})
      @model_options = Hash[options.map {|k,v| [k.to_sym, v]}]
    end

    def triples(subject, predicate, object, options={})
      model = (Thread.current[:model] ||= Redlander::Model.new @model_options)

      map_method = options[:only]
      map_method = if map_method && self.respond_to?(map_method, true)
                     self.method(map_method)
                   else
                     self.method(:all)
                   end

      triples = model.statements.each(
        :subject => uri_node(subject),
        :predicate => uri_node(predicate),
        :object => options[:object_literal] ? literal_node(object) : uri_node(object)
      )
      if block_given?
        triples.each { |triple| yield map_method.call(triple) }
      else
        triples = triples.respond_to?(:lazy) ? triples.lazy : triples
        triples.map { |triple| map_method.call(triple) }
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
