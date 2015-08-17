#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

# requirements
require_cmd bundle

bundle exec thin \
  --daemonize \
  --pid  $EV_APP_PID_FILE \
  --port $EV_APP_PORT \
  --log  "$EV_APP_LOG" \
  --rackup applications/evidence/config.ru \
  restart
