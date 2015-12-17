#!/bin/sh

# clear RUBYOPT; set on gentoo to auto require a missing gem
# (https://groups.google.com/forum/#!topic/linux.gentoo.user/Gp5xhTtYoUA)
export RUBYOPT=""
export OB_RUBY_VERSION="$(cat $DIR/.ruby-version)"
export OB_RUBY_BUILD_DIR="${OB_RUBY_BUILD_DIR:=$DIR/tools/libraries/ruby-build}"
export OB_RUBY_DIR="${OB_RUBY_DIR:=$DIR/vendor/ruby-$OB_RUBY_VERSION}"
export OB_GEM_DIR="${OB_GEM_DIR:=$DIR/vendor/gems}"
export OB_GEMBIN_DIR="${OB_GEMBIN_DIR:=$DIR/bin}"

PATH="$OB_RUBY_DIR/bin:$OB_RUBY_BUILD_DIR/bin:$OB_GEMBIN_DIR:$PATH"
