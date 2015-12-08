#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pull in standard functions, e.g., default.
source "$DIR/.gosh.sh" || return 1
default CUSTOM_ENV_SH "$DIR/env.sh.custom"
assert_source "$CUSTOM_ENV_SH" || return 1

### GENERAL ENV VARS ###
default DIR                     "$DIR"
default CUSTOM_ENV_SH           "$DIR/env.sh.custom"
default CTAG_INCLUDES           "Gemfile Rakefile app/ lib/"

### PATHS ###
default CONFIGS                 "$DIR"/config
default SCRIPTS                 "$DIR"/tools/scripts
default DOCS                    "$DIR"/docs
default TESTS                   "$DIR"/tests
default TESTS_API_SPEC          "$TESTS/api-specification"
default OUT                     "$DIR"/out
default OUT_TEST_RESULTS        "$OUT"/test-results

### SERVER PARAMETERS ###
default PID_FILE                "$DIR"/server.pid
default PORT_START              9000
default WORKER_COUNT            1
default THREADED                1
default THREAD_MIN              1
default THREAD_MAX              8
default SERVER_AS_DAEMON        0
default OUT_SERVER_STDOUT       "$OUT"/api-stdout.log
default OUT_SERVER_STDERR       "$OUT"/api-stderr.log

### DOC PARAMETERS ###
default DOC_API_SPEC            "$DOCS/openbel-api.raml"
default DOC_SCHEMAS             "$DOCS/schemas"

### TEST PARAMETERS ###
default ABAO_TEST_REPORTER      "min"
default TEST_HOST_URL           "http://localhost:$PORT_START"
default TEST_API_ROOT_URL       "$TEST_HOST_URL/api"
default TEST_URLS_FILE          "$TESTS/urls"

### THE GO SHELL ###
default GOSH_SCRIPTS            "$DIR"/tools/scripts
default GOSH_CONTRIB            "$SCRIPTS"/gosh-contrib

