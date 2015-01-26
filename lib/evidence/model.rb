require 'pp'

module OpenBEL
  module Model
    module Evidence

      # XXX This evidence model should be defined in bel.rb. Move.
      class Evidence

        attr_reader :bel_statement, :citation, :context, :summary_text

        def initialize(evidence_object, options = {})
          return nil unless evidence_object

          if [:to_h, :to_hash].any? { |m| evidence_object.respond_to?(m) }
            evidence_object.each { |k,v|
              send("#{k}=",v)
            }
          elsif evidence_object.respond_to? :to_s
            @bel_statement = evidence_object.to_s
          end

          unless @bel_statement
            fail ArgumentError.new("bel_statement is not set")
          end
        end

        def bel_statement= statement
          @bel_statement = statement.to_s
        end

        def citation= citation
          @citation = citation
        end

        def context= context
          @context =
            if context.respond_to? :to_h
              context.to_h
            else
              context.to_hash
            end
        end

        def summary_text= summary_text
          @summary_text = summary_text.to_s
        end

        def metadata
          @metadata ||= {}
        end

        def metadata= metadata
          @metadata =
            if metadata.respond_to? :to_h
              metadata.to_h
            else
              metadata.to_hash
            end
        end

        def ==(other)
          # TODO compare fully
          return false if other == nil
          @bel_statement == other.bel_statement
        end

        def hash
          [@bel_statement, @citation, @context, @summary_text, @metadata].hash
        end

        def to_h
          instance_variables.inject({}) { |res, attr|
            res.merge({attr[1..-1] => instance_variable_get(attr)})
          }
        end

        alias to_hash to_h

        def to_bel
          # TODO BEL conversion through bel.rb
          self.to_s
        end

        def to_s
          self.pretty_inspect
        end
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
