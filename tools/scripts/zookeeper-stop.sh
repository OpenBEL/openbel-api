#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

"$TOOLS_KAFKA"/bin/zookeeper-server-stop.sh \
  "$CONFIG"/zookeeper.properties

