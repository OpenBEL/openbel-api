#!/usr/bin/env bash

# The next three lines are for the go shell.
export SCRIPT_NAME="build docs"
export SCRIPT_HELP="Bulid documentation."
[[ "$GOGO_GOSH_SOURCE" -eq 1 ]] && return 0

# Normal script execution starts here.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
. "$DIR"/env.sh || exit 1

"$SCRIPTS"/docs-build.sh

