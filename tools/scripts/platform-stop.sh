#!/usr/bin/env bash

# Stops the platform.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

SESSION_LIST=$(tmux list-sessions 2>/dev/null | grep "^obp: ")
if [ -z "$SESSION_LIST" ]; then
    echo "The platform has not been started." 1>&2
    exit 1
fi

tools/scripts/service-evidence-document-storage-stop.sh
tools/scripts/api-rest-stop.sh
tools/scripts/kafka-stop.sh
killall nginx

tmux kill-session -t obp || exit 1
exit 0
