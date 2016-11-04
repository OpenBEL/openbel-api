FROM debian:8

RUN apt-get update && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

RUN ["/bin/bash", "mkdir", "-p", "/data"]

WORKDIR /data

ENV BIORDF_DB http://example.com/testme

RUN curl -SL $BIORDF_DB

VOLUME ['/data/biological-concepts-rdf.db']
