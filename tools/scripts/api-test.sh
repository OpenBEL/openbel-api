#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1
use_gosh_contrib || exit 1
assert_env TESTS || exit 1

# Root of where node_modules will go
export GOSH_CONTRIB_NODE_NPM_MODPATH="$TESTS"
export GOSH_CONTRIB_NODE_NPM_PKGJSON="$TESTS"/package.json

# Create the node environment if needed...
pushd "$TESTS" > /dev/null

  create_node_env
  # ... and use it.
  export PATH="$GOSH_CONTRIB_NODE_NPM_MODPATH/node_modules/.bin":$PATH

popd > /dev/null

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

echo "RUN TESTS"

# run test against api specification
"$TESTS_API_SPEC"/test.sh
TEST_EC=$?
if [ $TEST_EC -ne 0 ]; then
  echo "=> Failure validating API to its specification (exit $TEST_EC)" 2>&1
fi

# stop api
"$SCRIPTS"/api-stop.sh

exit $TEST_EC
