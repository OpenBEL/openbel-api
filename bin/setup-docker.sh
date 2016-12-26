#!/usr/bin/env bash

# run via: bash <(curl -s https://raw.githubusercontent.com/OpenBEL/openbel-api/master/bin/setup-docker.sh)

hash docker 2>/dev/null || { echo >&2 "I require docker. Please install.  Aborting."; exit 1; }
hash docker-compose 2>/dev/null || { echo >&2 "I require docker-compose. Please install.  Aborting."; exit 1; }


ssh_status=$(ssh -o BatchMode=yes -o ConnectTimeout=5 git@github.com 2>&1)

if [[ $ssh_status == *"successfully authenticated"* ]] ; then
  clone_cmd="git clone git@github.com:OpenBEL/openbel-api.git";
else
  clone_cmd="git clone https://github.com/OpenBEL/openbel-api.git";
fi

if [ ! -d "openbel-api" ]; then
    $clone_cmd
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

if [ ! -f "$HOME/config/config.yml" ]; then
    cp config/config.yml.example config/config.yml
fi

printf "Remember to configure config/config.yml\n\n"

echo "To start the dev docker instance: "
echo "  docker-compose build"
echo "  docker-compose up"

printf "\n\nTo run production docker: "
echo "  docker-compose -f docker-compose-prod.yml build"
echo "  docker-compose -f docker-compose-prod.yml up"