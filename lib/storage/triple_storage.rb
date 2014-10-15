module OpenBEL
  module Storage
    module TripleStorage

      def triples(subject, predicate, object, options={})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      protected

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
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
