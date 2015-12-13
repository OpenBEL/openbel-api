# openbel-api

The OpenBEL API provides RESTful API access to your BEL content. It is part of [OpenBEL Platform][OpenBEL Platform].

## Features

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

## API Documentation

The REST API is defined by a [RAML][RAML] specification. The specification is published [here][OpenBEL API RAML specification].

API documentation with *Try it* functionality is available [here][OpenBEL API documentation].

## Vocabulary

*Annotation*
A name/value property that describes an aspect of an *Evidence*. For example *Ncbi Taxonomy*:*Homo sapiens* is an annotation for the Human species.

*Namespace*
A biological identifier that is curated and maintained by an organization. For example the *Gene Ontology* (i.e. *GO*) or *HGNC* (i.e. *HUGO Gene Nomenclature Committee*) database.

*Evidence*
A biological interaction curated from scientific literature. It is comprised of five parts.

- *Citation*: The identification for the scientific literature where the interaction was stated.
- *BEL Statement*: The biological interaction curated from the *Citation*.
- *Summary text*: The text (i.e. *quotation*) within the *Citation* that supports the *BEL Statement*.
- *Experiment Context*: The biological context within the experiment where the *BEL Statement* was observed. For example if the experiment sample was a biopsy on Human, Lung tissue then you might provide *Ncbi Taxonomy*: *Homo sapiens* and *Uberon*: *lung epithelium*.
- *Metadata*: Additional data about this *Evidence* that is not part of the experiment (i.e. in *Experiment Context*). For example the evidence's *Reviewer*, *Create Date*, or *Reviewed Date* would be considered metadata.
- *References*: The annotation and namespace sources used in the *BEL Statement*, *Experiment Context*, and *Metadata*. For example *Ncbi Taxonomy* may refer to an annotation identified by the URI http://www.openbel.org/bel/namespace/ncbi-taxonomy.

*Document*: A file containing a collection of *Evidence* with document metadata like *Name*, *Description*, and *Version*. The supported document formats are BEL script, XBEL, and JSON Evidence.

*Dataset*: The representation of a *BEL Document* within the OpenBEL API. This provides access to document metadata as well as the collection of *Evidence* stored in the OpenBEL API that originate from the *BEL Document*.

*Expression*: A string encoded in BEL that may represent a parameter (e.g. *AKT1*, *GO:"apoptotic process"*), term (e.g. *bp(GO:"apoptotic process")*), or statement (e.g. *p(HGNC:AKT1) increases bp(GO:"apoptotic process")*).

*Evidence Store*: A database used for *Evidence*. It facilitates storage, filtering, and transformation of *Evidence*.

## Getting up and Running

-----

Built with collaboration and :heart: by the [OpenBEL][OpenBEL] community.

[OpenBEL]: http://www.openbel.org
[OpenBEL Platform]: https://github.com/OpenBEL/openbel-platform
[RAML]: http://raml.org/
[OpenBEL API RAML specification]: http://next.belframework.org/openbel-api.raml
[OpenBEL API documentation]: http://next.belframework.org/
[Evidence API documentation]: http://next.belframework.org/#evidence

