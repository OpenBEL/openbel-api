require_relative 'triple_storage'

module OpenBEL
  module Storage
    class CacheProxy
      include TripleStorage

      def initialize(real_storage, cache)
        if !real_storage or !real_storage.respond_to?(:triples)
          fail ArgumentError, "real_storage is invalid."
        end
        if !cache or !cache.respond_to?(:[])
          fail ArgumentError, "cache is invalid."
        end
        @real_storage = real_storage
        @cache = cache
      end

      def triples(subject, predicate, object, options={})
        pattern_key = key(subject, predicate, object)
        rdf_value = @cache[pattern_key]
        map_method = options.delete(:only)
        if rdf_value
          return [] if rdf_value == ""
          triples = unpack(rdf_value).each_slice(3)
        else
          triples = @real_storage.triples(subject, predicate, object, options).to_a
          if triples.empty?
            @cache[pattern_key] = ""
          else
            rdf_value = triples.map { |stmt|
              [subject(stmt), predicate(stmt), object(stmt)]
            }.flatten
            @cache[pattern_key] = pack(rdf_value)
          end
          triples
        end

        map_method = if map_method && @real_storage.respond_to?(map_method)
                       @real_storage.method(map_method)
                     else
                       @real_storage.method(:all)
                     end
        if block_given?
          triples.each { |triple| yield map_method.call(triple) }
        else
          triples = triples.respond_to?(:lazy) ? triples.lazy : triples
          triples.map { |triple| map_method.call(triple) }
        end
      end

      private

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
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
