# Build and run process (mongo + openbel-api).

# 1. Create docker network to allow mongo and openbel-api containers to talk.
#    docker network create openbel-network
# 2. Run mongo:3.2 container (available on docker registry).
#    docker run --name mongodb --net=openbel-network mongo:3.2
#    (nb: "mongodb" must be used as the name; openbel-api uses this as the host)
# 3. Build openbel-api dev docker image.
#    cd containers/api/
#    docker build -t openbel:openbel-api .
# 4. Run openbel-api as container.
#    docker run \
#      --name openbel-api --net=openbel-network --publish 9292:9292 \
#      --volume "$(realpath ../../):/app" \
#      {IMAGE ID from #3}

FROM jruby:9.1

# the container will expose 9292
# must run with port binding: -p 9292:9292
EXPOSE 9292

# needed by JRuby to fake building C extensions
RUN apt-get -y update && apt-get install -y make

# setup /data
# - /data/rdf_resources/ to hold sqlite db (biological-concepts-rdf.db)
# - /data/rdf_store/ to hold rdf store
# - copy over SQLite database used for searching annotations and namespaces
# - copy over RDF store used for storing datasets and annotation/namespace RDF
#   (consistent resource versions must be used between SQLite db and RDF store)
RUN ["mkdir", "-p", "/data/rdf_resources"]
RUN ["mkdir", "-p", "/data/rdf_store"]

# setup /app
# - holds mounted openbel-api volume for development
RUN ["mkdir", "-p", "/app"]
VOLUME /app

COPY run-developer-build.sh /
# COPY config.yml /

CMD ["./run-developer-build.sh"]
# vim: ft=dockerfile
