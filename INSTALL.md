## Install

This library requires [Ruby](https://www.ruby-lang.org) (**>= 2.0.0**).  See [how to install ruby](https://github.com/OpenBEL/bel.rb/blob/master/INSTALL_RUBY.md).

#### From RubyGems

Install from [RubyGems.org](http://rubygems.org/gems/openbel-api)

```bash
    gem install openbel-api
```

Run with `openbel-api --file your_config.yml`

You can obtain an example configuration file with `openbel-config`.

#### On Docker

First you will need to install [Docker](https://www.docker.com/).

- Linux: Install `docker` and `docker-compose` from your package manager.
- Mac OSX / Windows: Install [Docker Machine](https://docs.docker.com/machine/install-machine/) and
  [Docker Compose](https://docs.docker.com/compose/install/) by following the instructions on the Docker site.

Then you will need to obtain RDF resources and full-text search database containing
biological concepts (e.g. annotation, namespaces). Download data from
[OpenBEL Build Server](https://build.openbel.org/browse/OR).

- Copy RDF resources to `data` and name it `rdf_store`.
- Copy full-text search SQLite database to `data/rdf_resources` and name it `biological-concepts-rdf.db`.

Now you can build *openbel-api* using the *docker-compose-prod.yml* docker compose
layout.

`docker-compose --file docker-compose-prod.yml`

Once complete you can run all *openbel-api* processes with:

`docker-compose --file docker-compose-prod.yml up`

Note: You may have to set a longer `COMPOSE_HTTP_TIMEOUT` if you receive this error:

```
ERROR: An HTTP request took too long to complete. Retry with --verbose to obtain debug information.
If you encounter this issue regularly because of slow network conditions, consider setting COMPOSE_HTTP_TIMEOUT to a higher value (current value: 60).
```

This can be done with the command: `export COMPOSE_HTTP_TIMEOUT=300` (5 minutes)

The *openbel-api* on docker is successful when you see *mongodb_1* and *api_1* start up
successfully:

```
openbel-api_1   | Puma starting in single mode...
openbel-api_1   | * Version 3.1.0 (jruby 2.3.1), codename: El Niño Winter Wonderland
openbel-api_1   | * Min threads: 1, max threads: 2
openbel-api_1   | * Environment: development
mongodb_1       | 2016-11-22T01:14:40.986+0000 I NETWORK  [initandlisten] connection accepted from 172.19.0.4:54350 #1 (1 connection now open)
mongodb_1       | 2016-11-22T01:14:41.049+0000 I NETWORK  [conn1] end connection 172.19.0.4:54350 (0 connections now open)
mongodb_1       | 2016-11-22T01:14:41.052+0000 I NETWORK  [initandlisten] connection accepted from 172.19.0.4:54352 #2 (1 connection now open)
mongodb_1       | 2016-11-22T01:14:41.058+0000 I NETWORK  [conn2] end connection 172.19.0.4:54352 (0 connections now open)
mongodb_1       | 2016-11-22T01:14:41.064+0000 I NETWORK  [initandlisten] connection accepted from 172.19.0.4:54354 #3 (1 connection now open)
openbel-api_1   | log4j:WARN No appenders could be found for logger (org.apache.jena.info).
openbel-api_1   | log4j:WARN Please initialize the log4j system properly.
openbel-api_1   | log4j:WARN See http://logging.apache.org/log4j/1.2/faq.html#noconfig for more info.
mongodb_1       | 2016-11-22T01:14:41.795+0000 I NETWORK  [conn3] end connection 172.19.0.4:54354 (0 connections now open)
openbel-api_1   | * Listening on tcp://0.0.0.0:9292
openbel-api_1   | Use Ctrl-C to stop
```
