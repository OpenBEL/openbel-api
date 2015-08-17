#!/usr/bin/env bash

# The next three lines are for the go shell.
export SCRIPT_NAME="server loop"
export SCRIPT_HELP="Restarts the server on file system changes."
[[ "$GOGO_GOSH_SOURCE" -eq 1 ]] && return 0

# Normal script execution starts here.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
. "$DIR"/env.sh || exit 1

"$SCRIPTS"/api-server-loop.sh

