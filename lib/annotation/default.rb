require_relative 'api'
require_relative 'model'

# XXX platform-dependency
require_relative '../model/rdf_resource'

module OpenBEL
  module Annotation

    class Annotation
      include API

      BEL_ANNOTATION_CONCEPT_SCHEME = 'http://www.openbel.org/vocabulary/AnnotationConceptScheme'
      BEL_PREFIX = 'http://www.openbel.org/vocabulary/prefix'
      DC_IDENTIFIER = 'http://purl.org/dc/terms/identifier'
      RDF_TYPE = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
      SKOS_PREF_LABEL = 'http://www.w3.org/2004/02/skos/core#prefLabel'
      SKOS_IN_SCHEME = 'http://www.w3.org/2004/02/skos/core#inScheme'

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
        annotation_uri = find_annotation_rdf_uri(annotation)
        return nil unless annotation_uri

        annotation_by_uri(annotation_uri)
      end

      def find_annotation_value(annotation, value, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def search(match, options = {})
        if (match || '').empty?
          fail ArgumentError, "match cannot be empty"
        end

        @search.search(
          match,
          :type => 'annotation_value'
        )
      end

      def search_annotation(annotation, match, options = {})
        annotation_uri = find_annotation_rdf_uri(annotation)
        return nil unless annotation_uri

        @search.search(
          match,
          :type => 'annotation_value',
          :scheme_uri => annotation_uri
        )
      end

      private

      def annotation_by_uri(scheme_uri)
        OpenBEL::Model::Annotation::Annotation.from(
          @storage.triples(scheme_uri, nil, nil).to_a
        )
      end

      def find_annotation_rdf_uri(annotation)
        return nil unless annotation

        if annotation.is_a? Symbol
          annotation = annotation.to_s
        end

        case annotation
        when OpenBEL::Model::Annotation::Annotation
          annotation.uri
        when String
          [
            self.method(:annotation_by_prefix),
            self.method(:annotation_by_pref_label)
          ].each do |m|
            uri = m.call(annotation)
            return uri if uri
          end
        end
      end

      def annotation_by_prefix(prefix)
        prefix = prefix.downcase
        @storage.triples(
          nil, BEL_PREFIX, prefix, :object_literal => true, :only => :subject
        ).find { |subject|
          annotation_concept_scheme?(subject)
        }
      end

      def annotation_by_pref_label(label)
        @storage.triples(
          nil, SKOS_PREF_LABEL, label, :object_literal => true, :only => :subject
        ).find { |subject|
          annotation_concept_scheme?(subject)
        }
      end

      def annotation_concept_scheme?(subject)
        @storage.triples(
          subject,
          RDF_TYPE,
          BEL_ANNOTATION_CONCEPT_SCHEME
        ).count() == 1
      end
    end
  end
end
