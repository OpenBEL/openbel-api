#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

# requirements
require_cmd java

"$TOOLS_KAFKA"/bin/zookeeper-server-start.sh \
  "$CONFIG"/kafka_zookeeper.properties

