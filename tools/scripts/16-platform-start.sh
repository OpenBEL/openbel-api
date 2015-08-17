#!/usr/bin/env bash

export SCRIPT_NAME="start platform"
export SCRIPT_HELP="start the OpenBEL Platform"
[[ "$GOGO_GOSH_SOURCE" -eq 1 ]] && return 0

# Normal script execution starts here.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
source "$DIR"/env.sh || exit 1

"$SCRIPTS"/platform-start.sh

