Tasks
-----

- [x] Implement normalization of BEL Statement using:

  - [x] bel.rb / BEL::Parser.parse(BEL STATEMENT)
  - [x] AST Transformation
  - [x] Namespace API (Storage API)

- [x] Hook into evidence-pipeline

- Introduce service to convert processed evidence to JSON-LD.

  - RDF/JSON does not support named graphs.
  - Jena has support for JSON-LD.
  - JSON consumes less space and is resource-centric like turtle.
  - All of inferred namespace resources totalled 3.1 Gb using Nquads and 2.0 Gb using RDF/JSON (with reduced spacing / minimal format).

    - It is worth noting that the minimal spacing saved about 1.0 Gb.

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

  - evidence-raw-events,       2 partitions
  - evidence-processed-events, 8 partitions

    - ~40 seconds to process evidence from raw to processed (i.e. normalized).
    - what gives?

