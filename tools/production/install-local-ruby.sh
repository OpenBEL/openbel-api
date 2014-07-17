#!/bin/sh

# move to root, set up environment
DIR="$(cd "$(dirname "$0")" && pwd)"/../../
. "$DIR/tools/term-colors.sh" || exit 1
. "$DIR/tools/production/env.sh" || exit 1

current_ruby_version() {
    local res="-1"
    if [ -f "$OB_RUBY_DIR/bin/ruby" ]; then
        res="$($OB_RUBY_DIR/bin/ruby -e '$stdout.write RUBY_VERSION')"
    fi
    printf -- "$res"
}

# install ruby
if [ "$(current_ruby_version)" != "$OB_RUBY_VERSION" ]; then
    if [ -d "$OB_RUBY_DIR" ]; then
        printf "$YELLOW! invalid ruby; removing existing dir: $OB_RUBY_DIR $NO_COLOR\n"
        rm -fr "$OB_RUBY_DIR"
    fi
    printf "$YELLOW! no local ruby; installing ruby $OB_RUBY_VERSION $NO_COLOR\n"
    ruby-build $OB_RUBY_VERSION $OB_RUBY_DIR || exit 1
fi
printf "$GREEN+ ruby $OB_RUBY_VERSION installed$NO_COLOR\n"

# install bundler
$OB_RUBY_DIR/bin/gem query --name-matches 'bundler' --installed > /dev/null
if [ $? -eq 1 ]; then
    printf "$YELLOW! installing bundler $NO_COLOR\n"
    $OB_RUBY_DIR/bin/gem install bundler
fi
printf "$GREEN+ bundler installed$NO_COLOR\n"

# vim: ts=4 sts=4 sw=4
