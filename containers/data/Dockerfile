FROM alpine

RUN ["mkdir", "-p", "/data/rdf_resources"]
RUN ["mkdir", "-p", "/data/rdf_store"]

COPY ./data/biological-concepts-rdf.db /data/rdf_resources/
COPY ./data/rdf_store /data/rdf_store

VOLUME /data

ENTRYPOINT ["tail", "-f", "/dev/null"]
