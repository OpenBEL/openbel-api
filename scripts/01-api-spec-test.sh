#!/usr/bin/env bash

# The next three lines are for the go shell.
export SCRIPT_NAME="API Tests"
export SCRIPT_HELP="Execute API specification tests."
[[ "$GOGO_GOSH_SOURCE" -eq 1 ]] && return 0

# Normal script execution starts here.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../
source "$DIR"/env.sh || exit 1

# just wrap test.sh
"$DIR"/tests/api-specification/test.sh

