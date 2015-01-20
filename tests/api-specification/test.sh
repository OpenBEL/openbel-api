#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
HOST_URL="http://next.belframework.org"

../node_modules/.bin/abao \
  "$DIR/docs/api-specification/openbel-api.raml" \
  $HOST_URL \
  --hookfiles "$DIR/tests/api-specification/*_hook.js" \
  --timeout 5000
