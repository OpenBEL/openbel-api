#XXX platform-dependency
require_relative '../model/rdf_resource'

module OpenBEL
  module Model
    module Namespace

      class Namespace < OpenBEL::Model::RdfResource
        attr_accessor :type, :prefLabel, :prefix, :domain
      end

      class NamespaceValue < OpenBEL::Model::RdfResource
        attr_accessor :inScheme, :type, :identifier,
                      :fromSpecies, :prefLabel, :title

        def namespace=(namespace)
          @namespace = namespace
        end

        def namespace
          @namespace
        end

        def match_text=(match_text)
          @match_text = match_text
        end

        def match_text
          @match_text
        end
      end

      class ValueEquivalence

        attr_accessor :value, :equivalences

        def initialize(value, equivalences)
          @value = value
          @equivalences = equivalences
        end

        def ==(other)
          return false if other == nil
          @value == other.value && @equivalences == other.equivalences
        end

        def to_hash
          instance_variables.inject({}) { |res, attr|
            res.merge({attr[1..-1] => instance_variable_get(attr)})
          }
        end
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
