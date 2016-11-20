openbel-data: data volume container
===================================

This data volume container holds the:

- *rdf_store*: Jena RDF database that holds datasets and namespace RDF.
- *biological-concepts-rdf.db*: SQLite3 full-text search database for annotations and namespaces.

To use this you will need to:

- Copy your *rdf_store/* directory to *containers/data/data/*.
- Copy the *biological-concepts-rdf.db* to *containers/data/data/*.
- (optional) Build container with `docker builder -t openbel-data containers/data/`.

If you have copied the two files then you can then run `docker-compose build` directly from the
base of the repository.
