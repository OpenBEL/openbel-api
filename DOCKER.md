## OpenBEL API on Docker

The *openbel-api* repository includes both production and local
configurations.

OpenBEL API consists of the following images:

- MongoDB 3.2
- JRuby 9.1
- OpenBEL API
- Data container (for RDF resources)

The developer docker layout is defined in *docker-compose.yml*.

The production docker layout is defined in *docker-compose-prod.yml*.

To run either layout you will need to first build then start.

- `docker-compose --file choose-layout-file.yml build`
- `docker-compose --file choose-layout-file.yml up`

See [DEVELOPMENT.md](./DEVELOPMENT.MD) for more details.
