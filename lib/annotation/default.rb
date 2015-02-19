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
      DC_TITLE = 'http://purl.org/dc/terms/title'
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
        value_uri = find_annotation_value_rdf_uri(annotation, value)
        return nil unless value_uri

        annotation_value_by_uri(value_uri)
      end

      def find_annotation_values(annotation, options = {})
        fail NotImplementedError, "#{__method__} is not implemented"
      end

      def search(match, options = {})
        if (match || '').empty?
          fail ArgumentError, "match cannot be empty"
        end

        options = (options || {}).merge({:type => :annotation_value})
        @search.search(match, options).map { |result|
          annotation_value_by_uri(result.uri)
        }
      end

      def search_annotation(annotation, match, options = {})
        annotation_uri = find_annotation_rdf_uri(annotation)
        return nil unless annotation_uri

        options = (options || {}).merge({
          :type => :annotation_value,
          :scheme_uri => annotation_uri
        })
        @search.search(match, options).map { |result|
          annotation_value_by_uri(result.uri)
        }
      end

      private

      NAMESPACE_PREFIX = 'http://www.openbel.org/bel/namespace/'

      def find_annotation_rdf_uri(annotation)
        return nil unless annotation

        if annotation.is_a? Symbol
          annotation = annotation.to_s
        end

        case annotation
        when OpenBEL::Model::Annotation::Annotation
          return annotation.uri
        when String
          [
            self.method(:annotation_by_prefix),
            self.method(:annotation_by_pref_label),
            self.method(:annotation_by_uri_part)
          ].each do |m|
            uri = m.call(annotation)
            return uri if uri
          end
        end

        nil
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

      def annotation_by_uri_part(label)
        NAMESPACE_PREFIX + URI.encode(label)
      end

      def annotation_by_uri(scheme_uri)
        OpenBEL::Model::Annotation::Annotation.from(
          @storage.triples(scheme_uri, nil, nil).to_a
        )
      end

      def annotation_concept_scheme?(subject)
        @storage.triples(
          subject,
          RDF_TYPE,
          BEL_ANNOTATION_CONCEPT_SCHEME
        ).count() == 1
      end

      def find_annotation_value_rdf_uri(annotation, value)
        return nil unless value

        case value
        when OpenBEL::Model::Namespace::NamespaceValue
          return value.uri
        when URI
          return value
        when String
          annotation_uri = find_annotation_rdf_uri(annotation)
          return nil unless annotation_uri

          [
            self.method(:annotation_value_by_pref_label),
            self.method(:annotation_value_by_identifier),
            self.method(:annotation_value_by_title)
          ].each do |m|
            uri = m.call(annotation_uri, value)
            return uri if uri
          end
        end

        nil
      end

      def annotation_value_by_pref_label(annotation_uri, label)
        @storage.triples(
          nil, SKOS_PREF_LABEL, label, :object_literal => true, :only => :subject
        ).find { |subject|
          subject.start_with? annotation_uri
        }
      end

      def annotation_value_by_identifier(annotation_uri, id)
        @storage.triples(
          nil, DC_IDENTIFIER, id, :object_literal => true, :only => :subject
        ).find { |subject|
          subject.start_with? annotation_uri
        }
      end

      def annotation_value_by_title(annotation_uri, title)
        @storage.triples(
          nil, DC_TITLE, title, :object_literal => true, :only => :subject
        ).find { |subject|
          subject.start_with? annotation_uri
        }
      end

      def annotation_value_by_uri(uri)
        OpenBEL::Model::Annotation::AnnotationValue.from(
          @storage.triples(uri, nil, nil).to_a
        )
      end
    end
  end
end
