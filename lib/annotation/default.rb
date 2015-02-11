require_relative 'api'
require_relative 'model'

# XXX platform-dependency
require_relative '../model/rdf_resource'

module OpenBEL
  module Annotation

    class Annotation
      include API

      BEL_ANNOTATION_CONCEPT_SCHEME = 'http://www.openbel.org/vocabulary/AnnotationConceptScheme'
      RDF_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'

      def initialize(storage, search)
        fail(ArgumentError, "storage is invalid") unless storage
        fail(ArgumentError, "search is invalid") unless search
        @storage = storage
        @search  = search
      end

      def find_annotations(options = {})
        @storage.triples(
          nil, RDF_TYPE, BEL_ANNOTATION_CONCEPT_SCHEME, :only => :subject
        ).map { |scheme_uri|
          annotation_by_uri(scheme_uri)
        }.to_a
      end

      def find_annotation(annotation, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def find_annotation_value(annotation, value, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def search(match, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def search_annotation(annotation, match, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      private

      def annotation_by_uri(scheme_uri)
        OpenBEL::Model::Annotation::Annotation.from(
          @storage.triples(scheme_uri, nil, nil).to_a
        )
      end
    end
  end
end
