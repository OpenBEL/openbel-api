#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
. "$DIR"/env.sh || exit 1

"$SCRIPTS"/generate-tags.sh
"$SCRIPTS"/generate-cscope.sh

