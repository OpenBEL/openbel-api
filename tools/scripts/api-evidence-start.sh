#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

# requirements
require_cmd bundle

bundle exec thin \
  --port $EV_APP_PORT \
  --rackup applications/evidence/config.ru \
  start
