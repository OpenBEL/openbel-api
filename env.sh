#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -r "env.sh.custom" ]; then
    source env.sh.custom
fi

# -- Configuration --
export OB_RUBY_VERSION="$(cat $DIR/.ruby-version)"

# -- Locations --
export OB_RUBY_BUILD_DIR="${OB_RUBY_BUILD_DIR:=$DIR/tools/libraries/ruby-build}"
export OB_RUBY_DIR="${OB_RUBY_DIR:=$DIR/vendor/ruby-$OB_RUBY_VERSION}"
export OB_GEM_DIR="${OB_GEM_DIR:=$DIR/vendor/gems}"
export OB_GEMBIN_DIR="${OB_GEMBIN_DIR:=$DIR/bin}"

PATH="$OB_RUBY_DIR/bin:$OB_RUBY_BUILD_DIR/bin:$PATH"
# vim: ts=4 sts=4 sw=4
