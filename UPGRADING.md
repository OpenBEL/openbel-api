# Upgrading openbel-api

This files contains documentation for upgrading to specific versions of OpenBEL API.

## 0.6.0 Upgrade (2016-03-15)

### MongoDB 3.2

This release requires MongoDB >= 3.2. The latest MongoDB release is version [3.2.3](https://www.mongodb.com/mongodb-3.2) as of March 15th, 2016. OpenBEL API will fail to start (with message) if for MongoDB's version is less than 3.2.

-----

### MongoDB Migration

The 0.6.0 version of OpenBEL API introduces a change to how evidence facets are stored in MongoDB.

#### Change Detail

##### 0.5.1

Collections:

- `evidence`
  - Stores evidence.facets as strings.
- `evidence_facets`
  - Stores evidence facet objects for all searches.

##### 0.6.0

Collections:

- `evidence`
  - Stores evidence.facets as JSON objects for use in Mongo aggregation operations.
- `evidence_facet_cache`
  - Stores the facet collection name for each unique evidence search.
- `evidence_facet_cache_{UUID}`
  - Stores evidence facet objects for a specific evidence search.

#### Migration Procedure

Migrations are JRuby scripts that can be run directly as scripts (i.e. includes `#!/usr/bin/env jruby` shebang). You will need the OpenBEL API repository on GitHub as well as your OpenBEL API configuration file.

It is recommended to stop OpenBEL API and MongoDB before migrating.

1. Stop OpenBEL API.
2. Stop MongoDB daemon.
3. Clone OpenBEL API repository.
  - `git clone https://github.com/OpenBEL/openbel-api.git`
4. Change directory to the 0.6.0 migrations directory.
  - `cd openbel-api/tools/migrations/0.6.0`
5. Run *migrate_evidence_facets.rb* to update evidence.facets to JSON objects.
  - `./migrate_evidence_facets.rb YOUR_CONFIG.yml` or `jruby migrate_evidence_facets.rb YOUR_CONFIG.yml`
6. Run *drop_unused_collection.rb* to remove the old *evidence_facets* collection.
  - `./drop_unused_collection.rb YOUR_CONFIG.yml` or `jruby drop_unused_collection.rb YOUR_CONFIG.yml`
7. Start MongoDB daemon.
8. Start OpenBEL API.

-----

### Conflicting gem versions.

The *bel*, *puma*, and *rdf* gem dependencies have been upgraded. This may cause conflicting gem versions to exist in the same *GEM_HOME* location.

If you wish to install into an existing *GEM_HOME* (versus an isolated *GEM_HOME*) then please uninstall these gems:

- `gem uninstall bel puma rdf`
- Say yes to remove existing command scripts as well.

-----

### Installation

Install OpenBEL API 0.6.0 with `gem install openbel-api --version 0.6.0`.
