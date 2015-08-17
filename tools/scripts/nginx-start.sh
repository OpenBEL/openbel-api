#!/usr/bin/env bash

# Starts Nginx.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. "$DIR"/env.sh || exit 1

if [ ! -d "$OUT" ]; then
    mkdir "$OUT"
fi

# background nginx master process
exec nginx -c "${NGINX_CONFIG_FILE}"

