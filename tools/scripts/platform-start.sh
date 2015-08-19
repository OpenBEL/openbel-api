#!/usr/bin/env bash

# Starts the platform.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1

# NOTE: env.sh is not sourced here!
# We avoid sourcing env.sh here since each variable will be set in every TMUX
# window. By avoiding sourcing env.sh here, env.sh variables can be changed and
# reflected in running components w/out restarting the TMUX session.

SESSION_LIST=$(tmux list-sessions 2>/dev/null | grep "^obp: ")
if [ ! -z "$SESSION_LIST" ]; then
    [[ $NO_ATTACH -eq 1 ]] && exit 0
    tmux attach -t obp || exit 1
    exit 0
fi
tmux new-session -s obp    -n zookeeper         -d "./go.sh 14"   || exit 1
tmux new-window  -t obp:2  -n kafka             -d "./go.sh 12"   || exit 1

sleep 1s

tmux new-window  -t obp:3  -n nginx             -d "./go.sh 16"   || exit 1

# services
tmux new-window  -t obp:4  -n srvc-doc-storage0 -d "tools/scripts/service-evidence-document-storage-run.sh --kafka-partition 0"   || exit 1
tmux new-window  -t obp:5  -n srvc-doc-storage1 -d "tools/scripts/service-evidence-document-storage-run.sh --kafka-partition 1"   || exit 1
tmux new-window  -t obp:6  -n srvc-pipeline0    -d "tools/scripts/service-evidence-pipeline-run.sh --consumer-partition 0"        || exit 1
tmux new-window  -t obp:7  -n srvc-pipeline1    -d "tools/scripts/service-evidence-pipeline-run.sh --consumer-partition 1"        || exit 1
tmux new-window  -t obp:8  -n srvc-pipeline2    -d "tools/scripts/service-evidence-pipeline-run.sh --consumer-partition 2"        || exit 1
tmux new-window  -t obp:9  -n srvc-pipeline3    -d "tools/scripts/service-evidence-pipeline-run.sh --consumer-partition 3"        || exit 1

# applications
tmux new-window  -t obp:10  -n rest-app          -d "./go.sh 1"    || exit 1
tmux new-window  -t obp:11  -n evidence-app      -d "./go.sh 4"    || exit 1

tmux attach -t obp || exit 1

