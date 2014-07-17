#!/bin/sh

DIR="$(cd "$(dirname "$0")" && pwd)"/../../
. "$DIR/tools/term-colors.sh" || exit 1
. "$DIR/tools/production/env.sh" || exit 1

$DIR/tools/production/check-system.sh
if [ $? -eq 1 ]; then
    . "$DIR/tools/production/install-local-ruby.sh"
else
    . "$DIR/tools/production/env.sh"
    printf "${YELLOW}! Installing local gems.${NO_COLOR}\n"
    bundle install \
        --path "$OB_GEM_DIR" \
        --binstubs "$OB_GEMBIN_DIR" \
        --local \
        --deployment
fi
# vim: ts=4 sts=4 sw=4
