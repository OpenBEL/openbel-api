#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pull in standard functions, e.g., default.
source "$DIR/.gosh.sh" || return 1
default CUSTOM_ENV_SH "$DIR/env.sh.custom"
assert_source "$CUSTOM_ENV_SH" || return 1

# GENERAL ENV VARS #
default DIR                     "$DIR"
default CUSTOM_ENV_SH           "$DIR/env.sh.custom"
default CTAG_INCLUDES           "Gemfile Rakefile app/ lib/"
default PORT_START              9000

# PATHS #
default CONFIG                  "$DIR"/config
default TOOLS                   "$DIR"/tools
default TOOLS_KAFKA             "$TOOLS"/kafka
default SCRIPTS                 "$TOOLS"/scripts
default DOCS                    "$DIR"/docs
default TESTS                   "$DIR"/tests
default TESTS_API_SPEC          "$TESTS/api-specification"
default OUT                     "$DIR"/out
default OUT_TEST_RESULTS        "$OUT"/test-results

# SERVER PARAMETERS #

  # NGINX #
  default NGINX_CONFIG_FILE       "$CONFIG/nginx.conf"

  # REST APP #
  default REST_APP_PID_FILE       "$OUT"/rest-app.pid
  default REST_PORT               $PORT_START
  default WORKER_COUNT            4
  default THREADED                1
  default THREAD_MIN              0
  default THREAD_MAX              2
  default REST_APP_LOG            "$OUT"/rest-app.log

  # EVIDENCE APP #
  default EV_APP_PID_FILE         "$OUT"/evidence-app.pid
  default EV_APP_PORT             9005
  default EV_APP_LOG              "$OUT"/evidence-app.log

  # ZOOKEEPER #
  default ZOOKEEPER_CLIENT_PORT   9010             # i.e. kafka inbound port
  default ZOOKEEPER_DATA_DIR      "$OUT"/zookeeper # data directory
  default ZOOKEEPER_TICK_TIME     2000             # client heartbeat interval
  default ZOOKEEPER_MAX_CONN      0                # i.e. no minimum per IP

  # KAFKA #
  default KAFKA_ZOOKEEPER_CONNECT "localhost:${ZOOKEEPER_CLIENT_PORT}"
  default KAFKA_HOST              "127.0.0.1"
  default KAFKA_PORT              9020
  default KAFKA_TOPIC_RAW         "evidence-raw-events"
  default KAFKA_TOPIC_PROCESSED   "evidence-processed-events"
  default KAFKA_TOPIC_RDF         "evidence-rdf-events"
  default KAFKA_LOG_DIRS          "$OUT"/kafka-logs

  # GREENLINE #
  default OBP_GOPATH              "$DIR"/.gopath

# DOC PARAMETERS #
default DOC_API_SPEC            "$DOCS/openbel-api.raml"
default DOC_SCHEMAS             "$DOCS/schemas"

# TEST PARAMETERS #
default ABAO_TEST_REPORTER      "min"
default TEST_HOST_URL           "http://localhost:$PORT_START"
default TEST_API_ROOT_URL       "$TEST_HOST_URL/api"
default TEST_URLS_FILE          "$TESTS/urls"

# THE GO SHELL #
default GOSH_SCRIPTS            "$DIR"/tools/scripts
default GOSH_CONTRIB            "$SCRIPTS"/gosh-contrib

