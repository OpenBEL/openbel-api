#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

# requirements
require_cmd java

"$TOOLS_KAFKA"/bin/kafka-server-start.sh \
  "$CONFIG"/kafka_broker.properties \
  --override "zookeeper.connect=${KAFKA_ZOOKEEPER_CONNECT}" \
  --override "host.name=${KAFKA_HOST}" \
  --override "port=${KAFKA_PORT}" \
  --override "log.dirs=${KAFKA_LOG_DIRS}"

