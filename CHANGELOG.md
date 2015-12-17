# Change Log
All notable changes to openbel-api will be documented in this file. The curated log begins at changes to version 0.4.0.

This project adheres to [Semantic Versioning][Semantic Versioning].

## [0.5.0][0.5.0] - 2015-12-17
### Added
- Report API version from executables (`openbel-api`, `openbel-config`) and REST API (`GET /api/version`) ([Issue #91][91]).
- Support for MongoDB user authentication ([Issue #92][92]).
  - See [MongoDB User Authentication][MongoDB User Authentication].

### Changed
- Namespace value autocompletion will not return identifier-based namespace (e.g. Entrez Gene) suggestions unless the namespace prefix is used. For example "p(AKT" will not suggest "EGID:207" although "p(EG:AKT" will.

### Fixed
- Namespace value autocompletion will return the namespace prefix if the BEL term requires it. For example "p(AKT" will now suggest "HGNC:AKT1".
- Namespace value autocompletion now queries against the Resource RDF to lookup namespaces by prefix. Previously this resolves namespaces from hardcoded values in bel.rb.

-----

## 0.4.0 - 2015-12-14
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

[0.5.0]:                       https://github.com/OpenBEL/openbel-api/compare/0.4.0...0.5.0
[Semantic Versioning]:         http://semver.org
[MongoDB User Authentication]: https://github.com/OpenBEL/openbel-api/wiki/Configuring-the-Evidence-Store#mongodb-user-authentication
[91]:                          https://github.com/OpenBEL/openbel-api/issues/91
[92]:                          https://github.com/OpenBEL/openbel-api/issues/92
