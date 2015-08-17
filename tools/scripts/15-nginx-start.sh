#!/usr/bin/env bash

export SCRIPT_NAME="start nginx"
export SCRIPT_HELP="start the nginx web server"
[[ "$GOGO_GOSH_SOURCE" -eq 1 ]] && return 0

# Normal script execution starts here.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
source "$DIR"/env.sh || exit 1

"$SCRIPTS"/nginx-start.sh

