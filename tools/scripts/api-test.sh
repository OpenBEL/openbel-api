#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

# requirements
require_cmd curl

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

# run test against api specification
"$TESTS_API_SPEC"/test.sh
TEST_EC=$?
if [ $TEST_EC -ne 0 ]; then
  echo "=> Failure validating API to its specification (exit $TEST_EC)" 2>&1
fi

# stop api
"$SCRIPTS"/api-stop.sh

exit $TEST_EC
