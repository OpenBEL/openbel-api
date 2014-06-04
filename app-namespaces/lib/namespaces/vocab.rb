require 'rdf'

module OpenBEL

  class BELVocabulary < RDF::StrictVocabulary("http://www.openbel.org/vocabulary/")
    term :NamespaceConceptScheme,
      :label => "Namespace Concept Scheme",
      :type => "rdfs:Class",
      :subClassOf => "skos:ConceptScheme"
    property :prefix, :label => "Prefix for namespace"
    property :orthologousMatch, :label => "Relate SKOS concepts as orthologous"
  end
end
# vim: ts=2 sw=2
