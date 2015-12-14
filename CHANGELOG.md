# Change Log
All notable changes to openbel-api will be documented in this file. The curated log begins at changes to version 0.4.0.

This project adheres to [Semantic Versioning][Semantic Versioning].

## [0.4.0][0.4.0] - 2015-12-14
### Added
- Evidence Store
  - Storage of evidence including creation, retrieval, modification, and deletion actions.
  - Flexible filtering of stored, evidence based on user's custom data requirements.
  - Upload a document (e.g. BEL script, XBEL, or Evidence JSON), to the Evidence Store, as a dataset. These can later be retrieved or deleted from the Evidence Store.
  - Flexible filtering of evidence contained within a dataset.
  - Download a document (e.g. BEL script, XBEL, or Evidence JSON) from a dataset.
- BEL Expressions
  - Autocomplete a BEL term expression.
  - Retrieve the structural components of a BEL expression.
- Annotations and Namespaces
  - Retrieve annotation (e.g. Disease Ontology) and namespace (e.g. GO) data.
  - Retrieve equivalent namespace values from the individual.
  - Retrieve orthologous namespace values from the individual.

[Semantic Versioning]: http://semver.org
