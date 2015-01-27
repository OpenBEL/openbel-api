#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "${DIR}" || exit 1
. env.sh || exit 1

require_cmd ripper-tags
ripper-tags -R $CTAG_INCLUDES

