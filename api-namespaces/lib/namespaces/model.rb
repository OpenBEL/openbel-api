module OpenBEL
  module Namespace

    class Namespace

      ATTR_MAP = { prefLabel: 'name', prefix: 'prefix' }

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
              define_attribute('uri', s.subject, ns)
            else
              attribute = ATTR_MAP[attribute.to_sym]
              define_attribute(attribute, s.object, ns) if attribute
            end
          end
          (ns.respond_to? :uri and ns.uri) ? ns : nil
        end

        def from_statements!(statements)
          unless self.from_statements(statements)
            raise ArgumentError, "Statements do not describe NamespaceConceptScheme rdf:type."
          end
        end

        private
        def define_attribute(attribute, value, instance)
          if not instance.respond_to? attribute
            define_method(attribute) do
              instance_variable_get :"@#{attribute}"
            end
          end
          instance.instance_variable_set :"@#{attribute}", value
        end
      end
    end
  end
end
# vim: ts=2 sw=2
