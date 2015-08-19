#!/usr/bin/env bash

export SCRIPT_NAME="run service - evidence pipeline"
export SCRIPT_HELP="run the evidence pipeline service in the foreground"
[[ "$GOGO_GOSH_SOURCE" -eq 1 ]] && return 0

# Normal script execution starts here.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
source "$DIR"/env.sh || exit 1

"$SCRIPTS"/service-evidence-pipeline-run.sh

