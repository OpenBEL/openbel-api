PREFIX = """PREFIX belv: <http://www.openbel.org/vocabulary/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
"""

RULES = {

  subClassOf: """
    #{PREFIX}
    construct {
      ?i rdf:type ?target .
    } where {
      {
        # parent class
        ?i rdf:type ?type .
        ?type rdfs:subClassOf ?target .
      }
      UNION
      {
        # grand parent class
        ?i rdf:type ?type .
        ?type rdfs:subClassOf ?parent1 .
        ?parent1 rdfs:subClassOf ?target .
      }
      UNION
      {
        # great grand parent class
        ?i rdf:type ?type .
        ?type rdfs:subClassOf ?parent1 .
        ?parent1 rdfs:subClassOf ?parent2 .
        ?parent2 rdfs:subClassOf ?target .
      }
    }
  """,

  subPropertyOf: """
    #{PREFIX}
    construct {
      ?s ?target ?o .
    } where {
      {
        # up one property
        ?s ?p ?o .
        ?p rdfs:subPropertyOf ?target .
      }
      UNION
      {
        # up two properties
        ?s ?p ?o .
        ?p rdfs:subPropertyOf ?general1 .
        ?general1 rdfs:subPropertyOf ?target .
      }
      UNION
      {
        # up three properties
        ?s ?p ?o .
        ?p rdfs:subPropertyOf ?general1 .
        ?general1 rdfs:subPropertyOf ?general2 .
        ?general2 rdfs:subPropertyOf ?target .
      }
    }
  """
}
# vim: ts=2 sw=2
# encoding: utf-8
