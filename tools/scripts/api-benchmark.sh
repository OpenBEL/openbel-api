#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

# requirements
require_cmd bundle
require_cmd curl
require_cmd siege

SERVER_AS_DAEMON=1

# start api
"$SCRIPTS"/api-start.sh &

# poll until api root is reachable
curl -s "$TEST_API_ROOT_URL" 2>&1 > /dev/null
EC=$?
while [ $EC -ne 0 ]; do
  curl -s "$TEST_API_ROOT_URL" 2>&1 > /dev/null
  EC=$?
done

# call for siege tank
. "$SCRIPTS"/benchmark.sh

# stop api
"$SCRIPTS"/api-stop.sh
