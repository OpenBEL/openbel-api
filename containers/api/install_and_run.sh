#!/usr/bin/env bash

# Change to mounted openbel-api repository volume.
cd /app

# Install dependencies for openbel-api; sets up subprojects via local paths.
jruby -S bundle install

# Run openbel-api from /build.
cd /build
exec jruby -S openbel-api --file ./config.yml
