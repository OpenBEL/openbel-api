Tasks
-----

- [x] Implement normalization of BEL Statement using:

  - [x] bel.rb / BEL::Parser.parse(BEL STATEMENT)
  - [x] AST Transformation
  - [x] Namespace API (Storage API)

- [x] Hook into evidence-pipeline

- Design rdf-storage service using:

  - Jena
  - JRuby
  - rdf gem (Repository/Graph abstraction)


Measurements
------------

- Topic layout

  - evidence-raw-events,       2 partitions
  - evidence-processed-events, 4 partitions

    - 40 seconds to process evidence from raw to processed (i.e. normalized).
