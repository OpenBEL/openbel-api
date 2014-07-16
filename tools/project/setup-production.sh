#!/usr/bin/env bash

# move to root, set up environment
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
cd "$DIR" || exit 1
. env.sh || exit 1
. tools/term-colors.sh || exit 1

current_ruby_version() {
    local res='-1'
    if [ -f "$OB_RUBY_DIR/bin/ruby" ]; then
        res="$($OB_RUBY_DIR/bin/ruby -e '$stdout.write RUBY_VERSION')"
    fi
    echo "$res"
}

# install ruby
if [ "$(current_ruby_version)" != "$OB_RUBY_VERSION" ]; then
    echo -e "${YELLOW}! installing ruby ${OB_RUBY_VERSION}${NO_COLOR}"
    ruby-build $OPENBEL_RUBY_VERSION $OB_RUBY_DIR || exit 1
fi
echo -e "${GREEN}+ ruby ${OB_RUBY_VERSION} installed${NO_COLOR}"

# install bundler
$OB_RUBY_DIR/bin/gem query --name-matches 'bundler' --installed > /dev/null
if [ $? -eq 1 ]; then
    echo -e "${YELLOW}! installing bundler ${NO_COLOR}"
    $OB_RUBY_DIR/bin/gem install bundler
fi
echo -e "${GREEN}+ bundler installed${NO_COLOR}"

# install app gems through bundler
$OB_RUBY_DIR/bin/bundle install \
    --deployment \
    --without development test \
    --path "$OB_GEM_DIR" \
    --binstubs "$OB_GEMBIN_DIR"

# vim: ts=4 sts=4 sw=4
