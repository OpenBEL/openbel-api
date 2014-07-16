#!/bin/sh

# move to root, set up environment
DIR="$(cd "$(dirname "${0}")" && pwd)"/../../
cd "$DIR" || exit 1
. ./env.sh || exit 1
. ./tools/term-colors.sh || exit 1

# clear RUBYOPT; set on gentoo to auto require a missing gem
# (https://groups.google.com/forum/#!topic/linux.gentoo.user/Gp5xhTtYoUA)
export RUBYOPT=""

current_ruby_version() {
    local res='-1'
    if [ -f "$OB_RUBY_DIR/bin/ruby" ]; then
        res="$($OB_RUBY_DIR/bin/ruby -e '$stdout.write RUBY_VERSION')"
    fi
    printf "$res\n"
}

# install ruby
if [ "$(current_ruby_version)" != "$OB_RUBY_VERSION" ]; then
    if [ -d "$OB_RUBY_DIR" ]; then
        printf "${YELLOW}! invalid ruby; removing existing dir: ${OB_RUBY_DIR}${NO_COLOR}\n"
        rm -fr "${OB_RUBY_DIR}"
    fi
    printf "${YELLOW}! no local ruby; installing ruby ${OB_RUBY_VERSION}${NO_COLOR}\n"
    ruby-build $OB_RUBY_VERSION $OB_RUBY_DIR || exit 1
fi
printf "${GREEN}+ ruby ${OB_RUBY_VERSION} installed${NO_COLOR}\n"

# install bundler
$OB_RUBY_DIR/bin/gem query --name-matches 'bundler' --installed > /dev/null
if [ $? -eq 1 ]; then
    printf "${YELLOW}! installing bundler ${NO_COLOR}\n"
    $OB_RUBY_DIR/bin/gem install bundler
fi
printf "${GREEN}+ bundler installed${NO_COLOR}\n"

# install app gems through bundler
$OB_RUBY_DIR/bin/bundle install \
    --deployment \
    --without development test \
    --path "$OB_GEM_DIR" \
    --binstubs "$OB_GEMBIN_DIR"

# vim: ts=4 sts=4 sw=4
