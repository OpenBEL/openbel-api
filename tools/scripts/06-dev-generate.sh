#!/usr/bin/env bash

# The next three lines are for the go shell.
export SCRIPT_NAME="generate development files"
export SCRIPT_HELP="Generates development files like ctags, cscope, etc."
[[ "$GOGO_GOSH_SOURCE" -eq 1 ]] && return 0

# Normal script execution starts here.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
. "$DIR"/env.sh || exit 1

"$SCRIPTS"/generate-tags.sh
"$SCRIPTS"/generate-cscope.sh

