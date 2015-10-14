#XXX platform-dependency
require_relative '../model/rdf_resource'

module OpenBEL
  module Model
    module Annotation

      class Annotation < OpenBEL::Model::RdfResource
        attr_accessor :type, :prefLabel, :prefix, :domain
      end

      class AnnotationValue < OpenBEL::Model::RdfResource
        attr_accessor :inScheme, :type, :identifier, :prefLabel, :title

        def match_text=(match_text)
          @match_text = match_text
        end

        def match_text
          @match_text
        end
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2
# encoding: utf-8
