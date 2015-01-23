#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

if [ -z "$ABAO_TEST_REPORTER" ]; then
  ABAO_TEST_REPORTER=min
fi

# Test application/json responses.
"$TESTS"/node_modules/.bin/abao \
  "$DOC_API_SPEC" \
  "$TEST_HOST_URL" \
  --header "Accept:application/hal+json" \
  --hookfiles "$TESTS_API_SPEC/*_hook.js" \
  --timeout 5000 \
  --reporter "$ABAO_TEST_REPORTER"
