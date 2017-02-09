## OpenBEL API on Docker

The *openbel-api* repository includes both production and local
configurations.

OpenBEL API consists of the following images:

- MongoDB 3.2
- JRuby 9.1 (OpenBEL API)

First you will need to install [Docker](https://www.docker.com/).

- Linux: Install `docker` and `docker-compose` from your package manager.
- Mac OSX / Windows: Install [Docker](https://www.docker.com/products/docker) and
  [Docker Compose](https://docs.docker.com/compose/install/) by following the instructions on the Docker site.

### Getting started

The following bash command will do the following:

* check for the docker, docker-compose commands
* git clone or git pull depending on if 'openbel-api' director exists
* download the needed datasets from datasets.openbel.org
* copy /config/config.yml.example to /config/config.yml (you need to review this file!)
* provide commands to run to build and start dev or prod docker

    bash <(curl -s https://raw.githubusercontent.com/OpenBEL/openbel-api/master/bin/setup-docker.sh)

### Production docker

The production docker compose file is defined in *docker-compose-prod.yml*.

Run the following commands to start the production docker containers

    docker-compose -f docker-compose-prod.yml build
    docker-compose -f docker-compose-prod.yml up

You can then access the REST api at http://localhost:9292/api

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


To stop the docker containers

    docker-compose -f docker-compose-prod.yml stop

To change the port that production docker is running on, add ` -- --port <portnumber>`
to the production Dockerfile at the end of the CMD:

    CMD ["openbel-api", "--file", "/config/config.yml", "--", "--port", "9393"]

### Development docker

To start development:
    docker-compose build
    docker-compose up

You can then access the REST API at http://localhost:9292/api

Now with docker development you can change the code in the following directories
and have it automatically reload:

- `app/` (*openbel-api*)
- `lib/` (*openbel-api*)
- `subprojects/`
  - `bel/`
  - `bel_parser/`
  - `bel-rdf-jena/`
  - `bel-search-sqlite/`

#### Development Docker commands

Access running docker api container

    docker-compose exec openbel-api /bin/bash
    docker-compose exec mongodb /bin/bash

Logs

    docker-compose logs openbel-api

Clean up docker containers

    docker kill $(docker ps -q)
    docker rmi -f $(docker images -q -f dangling=true)


### Notes

You may have to set a longer `COMPOSE_HTTP_TIMEOUT` if you receive this error:

```
ERROR: An HTTP request took too long to complete. Retry with --verbose to obtain debug information.
If you encounter this issue regularly because of slow network conditions, consider setting COMPOSE_HTTP_TIMEOUT to a higher value (current value: 60).
```

This can be done with the command: `export COMPOSE_HTTP_TIMEOUT=300` (5 minutes)

