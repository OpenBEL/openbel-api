#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
source "$DIR"/env.sh || exit 1
use_gosh_contrib || exit 1
assert_env DOCS || exit 1

# Root of where node_modules will go
export GOSH_CONTRIB_NODE_NPM_MODPATH="$DOCS"
export GOSH_CONTRIB_NODE_NPM_PKGJSON="$DOCS"/package.json
cd "$DOCS" || exit 1

# Create the node environment if needed...
create_node_env
# ... and use it.
export PATH="$GOSH_CONTRIB_NODE_NPM_MODPATH/node_modules/.bin":$PATH

echo -en "Generating RAML page... "
OUT=$(mktemp)
raml2html \
    --template "$DOCS"/templates/template.nunjucks \
    "$DOCS"/openbel-api.raml > "$OUT"
EC=$?
if [ $EC -ne 0 ]; then
    echo FAIL
    cat $OUT || exit 1
    rm $OUT || exit 1
    exit $EC
else
    mv "$OUT" "$DOCS"/openbel-api.html || exit 1
    echo done
fi
exit 0

