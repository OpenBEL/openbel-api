#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

# requirements
require_cmd python3

echo "requirements done"

# start server if down
curl -s "$TEST_API_ROOT_URL" 2>&1 > /dev/null
EC=$?
if [ $EC -ne 0 ]; then
  # it is down; start it up chris
  "$SCRIPTS"/api-start.sh &

  curl -s "$TEST_API_ROOT_URL" 2>&1 > /dev/null
  EC=$?
  while [ $EC -ne 0 ]; do
    curl -s "$TEST_API_ROOT_URL" 2>&1 > /dev/null
    EC=$?
  done
fi

while true; do
  WATCHES=$(find "$DIR" -name "*.rb" | xargs dirname | xargs realpath | uniq)
  "$SCRIPTS"/gate ${WATCHES} || exit 1
  "$SCRIPTS"/api-restart.sh
  sleep 2
done

# stop server
"$SCRIPTS"/api-stop.sh
