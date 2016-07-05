# Upgrading openbel-api

This files contains documentation for upgrading to specific versions of OpenBEL API.

## 0.6.2 Upgrade (2016-03-23)

Follow the instructions to upgrade to 0.6.0

### Installation

Install OpenBEL API 0.6.2 with `gem install openbel-api --version 0.6.2`.

## 0.6.1 Upgrade (2016-03-16)

Follow the instructions to upgrade to 0.6.0.

### Installation

Install OpenBEL API 0.6.1 with `gem install openbel-api --version 0.6.1`.

## 0.6.0 Upgrade (2016-03-16)

### MongoDB 3.2

This release requires MongoDB >= 3.2. The latest MongoDB release is version [3.2.3](https://www.mongodb.com/mongodb-3.2) as of March 15th, 2016. OpenBEL API will fail to start (with message) if for MongoDB's version is less than 3.2.

Note: MongoDB 3.2 uses the *wiredTiger* storage engine by default. If you previously used the *mmapv1* storage engine for OpenBEL API then do not set *storage.engine* in your MongoDB configuration. MongoDB will determine the *storage.engine* by the data in your *dbPath*. See this [MongoDB article](https://docs.mongodb.org/manual/core/wiredtiger/) for details.

-----

### MongoDB Migration

The 0.6.0 version of OpenBEL API introduces a change to how nanopub facets are stored in MongoDB.

#### Change Detail

##### 0.5.1

Collections:

- `nanopub`
  - Stores nanopub.facets as strings.
- `nanopub_facets`
  - Stores nanopub facet objects for all searches.

##### 0.6.x

Collections:

- `nanopub`
  - Stores nanopub.facets as JSON objects for use in Mongo aggregation operations.
- `nanopub_facet_cache`
  - Stores the facet collection name for each unique nanopub search.
- `nanopub_facet_cache_{UUID}`
  - Stores nanopub facet objects for a specific nanopub search.

#### Migration Procedure

Migrations are JRuby scripts that can be run directly as scripts (i.e. includes `#!/usr/bin/env jruby` shebang). You will need the OpenBEL API repository on GitHub as well as your OpenBEL API configuration file.

It is recommended to stop OpenBEL API and MongoDB before migrating.

1. Stop OpenBEL API.
2. Stop MongoDB daemon.
3. Clone OpenBEL API repository.
  - `git clone https://github.com/OpenBEL/openbel-api.git`
4. Change directory to the 0.6.x migrations directory.
  - `cd openbel-api/tools/migrations/0.6.x`
5. Run *migrate_nanopub_facets.rb* to update nanopub.facets to JSON objects.
  - `./migrate_nanopub_facets.rb YOUR_CONFIG.yml` or `jruby migrate_nanopub_facets.rb YOUR_CONFIG.yml`
6. Run *drop_unused_collection.rb* to remove the old *nanopub_facets* collection.
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
