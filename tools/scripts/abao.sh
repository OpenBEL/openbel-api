#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
source "$DIR"/env.sh || exit 1
use_gosh_contrib || exit 1
assert_env TESTS || exit 1

# Root of where node_modules will go
export GOSH_CONTRIB_NODE_NPM_MODPATH="$TESTS"
export GOSH_CONTRIB_NODE_NPM_PKGJSON="$TESTS"/package.json
cd "$TESTS" || exit 1

# Create the node environment if needed...
create_node_env
# ... and use it.
export PATH="$GOSH_CONTRIB_NODE_NPM_MODPATH/node_modules/.bin":$PATH

echo -en "Running abao... "
abao || exit 1
# did we win?

