Tasks
-----

- [x] Implement normalization of BEL Statement using:

  - [x] bel.rb / BEL::Parser.parse(BEL STATEMENT)
  - [x] AST Transformation
  - [x] Namespace API (Storage API)

- [x] Hook into evidence-pipeline

- [x] Introduce service to convert processed evidence to nquads.

  - Pro: NQuads is simpler to parse and split due to its line-based format.
  - Con: It duplicates data such as the subject, predicate, and context.

- Design rdf-storage service using:

  - [x] Java 8
  - [x] Kafka
  - [x] Jena

- Re-read Kafka documentation, mostly the stuff on consumer groups, partitions, and parallelism.
- Devise experiment to test Kafka throughput and parallelism on a single machine.

  - Parameters

    - Number of partitions
    - Number of consumer processes within a group

      - In Ruby can I have a single process listen to all partitions?

        - This seems possible using Hermann/JRuby because you can query the partition information via zookeeper.

  - Measuring

    - Add a consumer on each topic to capture metrics?
    - Rate: messages / second (produced, consumed)


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

Topics and Partitions
---------------------

- Can we have one process consume from 4 partitions on Java and Ruby (i.e. Hermann)?

evidence-raw-events

Contains the raw evidence JSON documents flowing from the user.
Partitions: 4


evidence-processed-events

Contains the normalized evidence JSON documents. Converts raw evidence into processed evidence.
Partitions: 4


evidence-rdf-events

Contains the RDF representation of evidence. Converts processed evidence into RDF evidence.
Partitions: 4
