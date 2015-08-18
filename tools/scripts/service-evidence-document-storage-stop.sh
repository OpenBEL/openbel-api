#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

# requirements
require_cmd bundle

# service location
cd "$DIR/services/evidence-document-storage"

bundle exec ruby \
  ./service-control.rb \
  stop
