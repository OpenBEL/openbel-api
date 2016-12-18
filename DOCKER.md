# Docker Notes

This document describes how to use Docker for development and production deployment of the
OpenBEL API.

### Using Docker

#### Production docker

1. Make sure you add the search.db file to the containers/api folder.  This is the sqlite database with the namespaces, etc for use in the REST API.
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

