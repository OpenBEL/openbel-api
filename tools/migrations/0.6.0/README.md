## MongoDB Migrations for 0.6.0

The 0.6.0 version of OpenBEL API introduces a change to how evidence facets are stored in MongoDB.

### Change Detail

#### 0.5.1

Collections:

- `evidence`
  - Stores evidence.facets as strings.
- `evidence_facets`
  - Stores evidence facet objects for all searches.

#### 0.6.0

Collections:

- `evidence`
  - Stores evidence.facets as JSON objects for use in Mongo aggregation operations.
- `evidence_facet_cache`
  - Stores the facet collection name for each unique evidence search.
- `evidence_facet_cache_{UUID}`
  - Stores evidence facet objects for a specific evidence search.

### Migration Procedure

The migrations are JRuby scripts that can be run directly as scripts (i.e. includes `#!/usr/bin/env jruby` shebang). You will need the OpenBEL API repository on GitHub as well as your OpenBEL API configuration file.

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
