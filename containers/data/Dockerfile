FROM debian:8

ARG BIORDF_DB

RUN ["mkdir", "-p", "/data/rdf_resources"]

ADD $BIORDF_DB /data/rdf_resources/biological-concepts-rdf.db

# VOLUME ['/data/rdf_resources']
