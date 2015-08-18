#!/usr/bin/env bash

export SCRIPT_NAME="run service - evidence document storage"
export SCRIPT_HELP="run the evidence document storage service in the foreground"
[[ "$GOGO_GOSH_SOURCE" -eq 1 ]] && return 0

# Normal script execution starts here.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
source "$DIR"/env.sh || exit 1

"$SCRIPTS"/service-evidence-document-storage-run.sh

