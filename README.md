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

## Technical requirements

The OpenBEL API is built to run with [JRuby][JRuby] and [Java 8][Java 8].

*System Requirements*

- [Java 8][Java 8]
- [JRuby][JRuby], 9.x series (9.0.x.0 is recommended)
  - The 9.x series is required due to a Ruby language 2.0 requirement.
  - See "Installation" below for configuring JRuby and isolating the openbel-api application.
- [MongoDB][MongoDB], version 3.2 or greater
  - Follow [MongoDB download][MongoDB download] page for download and installation instructions.
- [SQLite][SQLite], version 3.8.0 or greater
  - Follow [SQLite download][SQLite download] page for download and installation instructions. 

## Getting up and Running

### Installation

The OpenBEL API is packaged and installed as a Ruby gem. A Ruby gem is packed library or application that runs on the Ruby virtual machine. In this case OpenBEL API runs only on [JRuby][JRuby].

#### JRuby Configuration

- Unpack JRuby archive.
- Export the JRUBY_HOME environment variable to the unpacked JRuby archive directory.
- Add "$JRUBY_HOME/bin" to your PATH environment variable.
- Export the GEM_HOME and GEM_PATH environment variable to any directory accessible to the current user. This is where JRuby gems will be installed. The OpenBEL API and dependencies will be installed into this directory for isolation from other Ruby applications running on the system.

*Example JRuby Configuration*

Assume that we have unpacked JRuby to `/opt/jruby`. We should then:

- Export `JRUBY_HOME` to `/opt/jruby`.
- Add `$JRUBY_HOME/bin` to our `PATH` environment variable.
- Export both `GEM_HOME` and `GEM_PATH` to `/opt/jruby/gems`.
- Add `$GEM_HOME/bin` to our `PATH` environment variable.
- Proceed with *Installation of OpenBEL API*.

#### Installation of OpenBEL API

Installation uses the [RubyGems][RubyGems] site to download and install the gem from. To install the OpenBEL API gem run the `gem install` command available within your [JRuby][JRuby] installation.

```bash
gem install openbel-api
```

All of the application dependencies needed by `openbel-api` will be installed during this process.

**Tip**
If the `openbel-api` executable is not available make sure `$GEM_HOME/bin` is included on your `PATH`. See *JRuby Configuration* above.

### Configuration

The OpenBEL API requires a configuration file to set up a few things. You can create an initial configuration file using the `openbel-config` command.

```bash
openbel-config --file openbel-api-config.yml
```

*Configure the Evidence Store*
The Evidence Store is backed by a [MongoDB][MongoDB] database. You will need to provide the *host*, *port*, and *database* option.

The default configuration is:

```yaml
evidence_store:
  mongo:
    host:     'localhost'
    port:     27017
    database: 'openbel'
```

There are also settings for user authentication. See [MongoDB User Authentication][MongoDB User Authentication] on the wiki.

*Resource RDF data*
Annotations, namespaces, and dataset storage are represented as [RDF][RDF] data. The data is stored in an on-disk database using Apache Jena (Java library included with `openbel-api`).

You will need to configure the location of the Apache Jena TDB database that holds this data.

The default configuration is:

```yaml
resource_rdf:
  jena:
    tdb_directory: 'biological-concepts-rdf'
```

**Tip**
You can obtain the latest Resource RDF database (20150611) from the [OpenBEL build server][Resource RDF 20150611].

*Resource search*
Annotations and namespaces can be full-text searched using a [SQLite][SQLite] database. The data is stored in an on-disk file.

The default configuration is:

```yaml
resource_search:
  sqlite:
    database_file: 'biological-concepts-rdf.db'
```


**Tip**
You can obtain the latest Resource Search database (20150611) from the [OpenBEL build server][Resource Search 20150611].

*Token-based authentication*
The OpenBEL API is equipped to require authentication for specific API paths (e.g. Evidence, Datasets). The implementation uses [Auth0][Auth0] as a single sign-on service.

By default authentication is disabled.

The default configuration is:

```yaml
# Set a secret used during session creation....
session_secret: 'changeme'

# User authentication using Auth0.
auth:
  enabled: false
  redirect: 'https://openbel.auth0.com/authorize?response_type=code&scope=openid%20profile&client_id=K4oAPUaROjbWWTCoAhf0nKYfTGsZWbHE'
  default_connection: 'linkedin'
  domain:   'openbel.auth0.com'
  id:       'K4oAPUaROjbWWTCoAhf0nKYfTGsZWbHE'
  # secret:   'auth0 client secret here'
```

### Running the OpenBEL API

The OpenBEL API can be run using the `openbel-api` command and passing a configuration file.

The configuration file can be provided in two ways:
- Command option (`--file`)
- Environment variable named `OPENBEL_API_CONFIG_FILE`

*Command option*
```
openbel-api --file "/path/to/openbel-api-config.yml"
```

*Environment variable*
```
export OPENBEL_API_CONFIG_FILE="/path/to/openbel-api-config.yml"

openbel-api
```

To configure server options such as port, background execution, or number of threads you will need to provide an extra set of arguments to the `openbel-api` command. These options help configure the [Puma HTTP server][Puma HTTP server] that is included with OpenBEL API.

*Example running on port 9000 with up to 16 threads.*

```bash
openbel-api --file openbel-api-config.yml -- --port 9000 --threads 1:16
```

**Note**
Run `openbel-api --help` for more information and options.

### Running behind Nginx (or another reverse proxy)

The OpenBEL API beings at the `/api` path. If you plan OpenBEL API behing a reverse proxy then you will want to setup a route to `/api`.

For example the following [Nginx][Nginx] configuration will proxy from `http://$hostname/api` to `http://localhost:9000/api`.

```
server {
    listen        0.0.0.0:80;
    server_name   $hostname;
    access_log    /var/log/nginx/access.log main;
    error_log     /var/log/nginx/error.log info;

    location /api {
        proxy_pass               http://localhost:9000;
        proxy_set_header         Host $host;
        proxy_set_header         X-Real-IP $remote_addr;
        proxy_set_header         X-Real-Base-URL $scheme://$host;
        proxy_set_header         X-Real-URL $scheme://$host$request_uri;
        proxy_buffer_size        128k;
        proxy_buffers            4 256k;
        proxy_busy_buffers_size  256k;
        client_max_body_size     50M;
    }
}
```

## API Documentation

The REST API is defined by a [RAML][RAML] specification. Th                is published [here][OpenBEL API RAML specification].

API documentation with *Try it* functionality is available [here][OpenBEL API documentation].

-----

Built with collaboration and a lot of :heart: by the [OpenBEL][OpenBEL] community.

[OpenBEL]: http://www.openbel.org
[OpenBEL Platform]: https://github.com/OpenBEL/openbel-platform
[RAML]: http://raml.org/
[OpenBEL API RAML specification]: http://next.belframework.org/openbel-api.raml
[OpenBEL API documentation]: http://next.belframework.org/
[Evidence API documentation]: http://next.belframework.org/#evidence
[JRuby]: http://jruby.org
[JRuby Getting Started]: http://jruby.org/getting-started
[Java 8]: http://www.oracle.com/technetwork/java/javase/overview/java8-2100321.html
[MongoDB]: https://www.mongodb.org/
[MongoDB download]: https://www.mongodb.org/downloads#production
[SQLite]: https://www.sqlite.org
[SQLite download]: https://www.sqlite.org/download.html
[RubyGems]: https://rubygems.org
[RDF]: http://www.w3.org/RDF/
[Auth0]: https://auth0.com/
[Puma HTTP server]: http://puma.io/
[Resource RDF 20150611]: http://build.openbel.org/browse/OR-RRD2/latestSuccessful/artifact
[Resource Search 20150611]: http://build.openbel.org/browse/OR-RSD2/latestSuccessful/artifact
[Nginx]: http://nginx.org/
[MongoDB User Authentication]: https://github.com/OpenBEL/openbel-api/wiki/Configuring-the-Evidence-Store#mongodb-user-authentication
