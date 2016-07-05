## MongoDB Migrations for 0.6.x

The 0.6.x version of OpenBEL API introduces a change to how nanopub facets are stored in MongoDB.

### Change Detail

#### 0.5.1

Collections:

- `nanopub`
  - Stores nanopub.facets as strings.
- `nanopub_facets`
  - Stores nanopub facet objects for all searches.

#### 0.6.x

Collections:

- `nanopub`
  - Stores nanopub.facets as JSON objects for use in Mongo aggregation operations.
- `nanopub_facet_cache`
  - Stores the facet collection name for each unique nanopub search.
- `nanopub_facet_cache_{UUID}`
  - Stores nanopub facet objects for a specific nanopub search.

### Migration Procedure

The migrations are JRuby scripts that can be run directly as scripts (i.e. includes `#!/usr/bin/env jruby` shebang). You will need the OpenBEL API repository on GitHub as well as your OpenBEL API configuration file.

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
