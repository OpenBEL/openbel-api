module OpenBEL
  module Model

    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods
      def from_statements(statements)
        obj = self.new
        statements.each do |s|
          uri = s.predicate.uri
          attribute = uri.fragment || uri.path[uri.path.rindex('/')+1..-1]
          if attribute == 'type' and obj.respond_to? :uri=
            obj.send(:uri=, s.subject.value.to_s)
          end
          if obj.respond_to? :"#{attribute}="
            obj.send(:"#{attribute}=", s.object.value.to_s)
          end
        end
        (obj.respond_to? :uri and obj.uri) ? obj : nil
      end
    end
  end

  module Namespace

    class Namespace
      include OpenBEL::Model

      attr_accessor :uri, :type, :prefLabel, :prefix

      def ==(other)
        return false if other == nil
        @uri == other.uri && @name == other.name && @prefix == other.prefix
      end

      def to_hash
        instance_variables.inject({}) { |res, attr|
          res.merge({attr[1..-1] => instance_variable_get(attr).value})
        }
      end

      def to_s
        @uri
      end
    end

    class NamespaceValue
      include OpenBEL::Model

      attr_accessor :uri, :inScheme, :type, :identifier,
                    :fromSpecies, :prefLabel, :title

      def ==(other)
        return false if other == nil
        @uri == other.uri && @name == other.name && @prefix == other.prefix
      end

      def to_hash
        instance_variables.inject({}) { |res, attr|
          res.merge({attr[1..-1] => instance_variable_get(attr).value})
        }
      end
    end
  end
end
# vim: ts=2 sw=2
