#!/usr/bin/env bash

# The next three lines are for the go shell.
export SCRIPT_NAME="raml2html"
export SCRIPT_HELP="Run raml2html over our RAML spec."
[[ "$GOGO_GOSH_SOURCE" -eq 1 ]] && return 0

# Normal script execution starts here.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
. "$DIR"/env.sh || exit 1

"$SCRIPTS"/raml2html.sh

