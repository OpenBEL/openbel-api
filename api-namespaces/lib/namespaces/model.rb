module OpenBEL
  module Namespace

    class Namespace

      ATTR_MAP = { prefLabel: 'name', prefix: 'prefix' }
      attr_accessor :uri, :name, :prefix

      def ==(other)
        return false if other == nil
        @uri == other.uri && @name == other.name && @prefix == other.prefix
      end

      def to_h
        instance_variables.inject({}) { |res, attr|
          res.merge({attr[1..-1] => instance_variable_get(attr).value})
        }
      end

      class << self
        def from_statements(statements)
          ns = self.new
          statements.each do |s|
            uri = s.predicate.uri
            attribute = uri.fragment || uri.path[uri.path.rindex('/')+1..-1]
            if attribute == 'type'
              ns.send(:uri=, s.subject)
            else
              attribute = ATTR_MAP[attribute.to_sym]
              if attribute
                ns.send(:"#{attribute}=", s.object)
              end
            end
          end
          (ns.respond_to? :uri and ns.uri) ? ns : nil
        end

        def define_attribute(attribute, value, instance)
          if not instance.respond_to? attribute
            define_method(attribute) do
              instance_variable_get :"@#{attribute}"
            end
          end
        end
      end
    end
  end
end
# vim: ts=2 sw=2
