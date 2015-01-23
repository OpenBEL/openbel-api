#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

# requirements
require_cmd siege

# lay siege
siege \
  --benchmark \
  --concurrent=100 \
  --time=30s \
  --file="$TEST_URLS_FILE"

