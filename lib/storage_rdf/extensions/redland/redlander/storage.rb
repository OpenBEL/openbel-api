require 'uri'
require 'redlander'
require 'kyotocabinet'

module OpenBEL
  module RedlanderStorage

    XSD_TYPE_URI = Redland.librdf_new_uri(Redlander.rdf_world, 'http://www.w3.org/2001/XMLSchema#string')

    # XXX Configuration
    QUERY_CACHE = KyotoCabinet::Db::FileHash.new '/tmp/db.kch', :writer, :create

    def model(options = {})
      Thread.current[:model] ||= Redlander::Model.new options
    end

    def statement_enumerator(subject, predicate, object, options = {})
      rdf_model = model(@model_options)

      key_id = key(subject, predicate, object)
      rdf = QUERY_CACHE[key_id]
      if rdf
        return [] if rdf == ""
        unpack(rdf).each_slice(3)
      else
        triples = rdf_model.statements.each(
          :subject => uri_node(subject),
          :predicate => uri_node(predicate),
          :object => options[:object_literal] ? literal_node(object) : uri_node(object)
        ).to_a

        # CACHE!
        if triples.empty?
          QUERY_CACHE[key_id] = ""
        else
          value = triples.map { |stmt|
            [subject(stmt), predicate(stmt), object(stmt)]
          }.flatten
          QUERY_CACHE[key_id] = pack(value)
        end

        triples
      end
    end

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

    private

    def uri_node(obj)
      return nil unless obj
      # Redland.librdf_new_node_from_uri_string(Redlander.rdf_world, obj.to_s)
      Redlander::Node.new(obj.to_s, :resource => true)
    end

    def literal_node(object)
      Redlander::Node.new(object.to_s)
      # Redland.librdf_new_node_from_typed_literal(Redlander.rdf_world, object.to_s, '', XSD_TYPE_URI)
    end

    def key(subject, predicate, object)
      pack([
        subject   == nil ? 'NULL' : subject.to_s,
        predicate == nil ? 'NULL' : predicate.to_s,
        object    == nil ? 'NULL' : object.to_s,
      ])
    end

    def pack(array)
      [array.join("\0")].pack('m0')
    end

    def unpack(value)
      return nil unless value
      value.unpack('m*')[0].split("\0")
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
