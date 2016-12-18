## OpenBEL API on Docker

The *openbel-api* repository includes both production and local
configurations.

OpenBEL API consists of the following images:

- MongoDB 3.2
- JRuby 9.1
- OpenBEL API
- Data container (for RDF resources)

The developer docker layout is defined in *docker-compose.yml*.
1. Then run the following commands

    docker-compose -f docker-compose-prod.yml build
    docker-compose -f docker-compose-prod.yml up

You can then access the REST api at http://localhost:9292/api


To stop the docker containers

    docker-compose -f docker-compose-prod.yml stop


#### Development docker

To start development:
    docker-compose build
    docker-compose up

You can then access the REST API at http://localhost:9292/api

### Development of Docker containers

Access running docker api container

    docker exec -it openbelapi_api_1 /bin/bash

Clean up docker containers

    docker kill $(docker ps -q)
    docker rmi -f $(docker images -q -f dangling=true)

