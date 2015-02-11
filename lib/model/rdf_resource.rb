module OpenBEL
  module Model

    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods
      def from(statements)
        obj = self.new
        statements.each do |sub, pred, obj_val|
          index = pred.rindex('#') || pred.rindex('/')
          if index
            attribute = pred[index+1..-1]
            if attribute == 'type' and obj.respond_to? :uri=
              obj.send(:uri=, sub)
            end
            if obj.respond_to? :"#{attribute}="
              obj.send(:"#{attribute}=", obj_val)
            end
          else
            $stderr.puts "cannot parse local name for #{pred}"
          end
        end
        (obj.respond_to? :uri and obj.uri) ? obj : nil
      end
    end

    class RdfResource
      include OpenBEL::Model

      def initialize(attr_values = {})
        attr_values.each { |k, v|
          instance_variable_set(:"@#{k}", v)
        }
      end

      attr_accessor :uri

      def ==(other)
        return false if other == nil
        @uri == other.uri
      end

      def hash
        @uri.hash
      end

      def to_hash
        instance_variables.inject({}) { |res, attr|
          res.merge({attr[1..-1] => instance_variable_get(attr)})
        }
      end

      def to_s
        @uri
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
