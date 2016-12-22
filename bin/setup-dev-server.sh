#!/usr/bin/env bash

# run via: bash <(curl -s https://raw.githubusercontent.com/OpenBEL/openbel-api/master/bin/setup-dev-server.sh)

hash docker 2>/dev/null || { echo >&2 "I require docker. Please install.  Aborting."; exit 1; }
hash docker-compose 2>/dev/null || { echo >&2 "I require docker-compose. Please install.  Aborting."; exit 1; }


if [ ! -d "openbel-api" ]; then
    git clone git@github.com:OpenBEL/openbel-api.git
else
    cd openbel-api;
    git pull;
    cd ..;
fi

cd openbel-api
git submodule update --init  # Update project submodules (in the ./subprojects directory)
HOME=$(pwd)


# Download and bunzip2 datasets
if [ ! -d "$HOME/data/rdf_resources" ]; then
    mkdir -p $HOME/data/rdf_resources
    cd $HOME/data/rdf_resources
    curl -O http://datasets.openbel.org/biological-concepts-rdf.db.bz2
    bunzip2 biological-concepts-rdf.db.bz2
fi

if [ ! -d "$HOME/data/rdf_store" ]; then
    mkdir -p $HOME/data
    cd $HOME/data
    curl -O http://datasets.openbel.org/rdf_store.tar.bz2
    bunzip2 rdf_store.tar.bz2
    tar xvf rdf_store.tar
    rm rdf_store.tar
fi

cd $HOME

cp config/config.yml.example config/config.yml

echo "Remember to configure config/config.yml"

docker-compose build

echo "Re-run docker-compose build if you changed config.yml"
echo "Now run docker-compose up to start the server"
