#!/bin/sh

DIR="$(cd "$(dirname "$0")" && pwd)"/../../
. "$DIR/tools/term-colors.sh" || exit 1
. "$DIR/tools/production/functions.sh" || exit 1

# check system
system_ruby_version=$(system_ruby)
DO_INSTALL=0
if [ "$system_ruby_version" != "-1" ]; then
    system_ruby_matches=$(ruby -e \
        "require 'rubygems'
         spec = Gem::Specification.load('openbel-server.gemspec')
         \$stdout.write spec.required_ruby_version =~ Gem::Version.new('${system_ruby_version}')")
    if [ "$system_ruby_matches" == "true" ]; then
        printf "$GREEN+ system ruby (version $system_ruby_version) meets requirements in openbel-server.gemspec$NO_COLOR\n"
    else
        printf "$RED! system ruby (version $system_ruby_version) does not meet requirements in openbel-server.gemspec$NO_COLOR\n"
        DO_INSTALL=1
    fi
else
        printf "$RED! system ruby (version $system_ruby_version) does not meet requirements in openbel-server.gemspec$NO_COLOR\n"
        DO_INSTALL=1
fi

exit $DO_INSTALL
# vim: ts=4 sts=4 sw=4
