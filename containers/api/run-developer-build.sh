#!/usr/bin/env bash

cd /app

bundle install --system

# export OPENBEL_API_CONFIG_FILE=/config.yml

exec jruby -S bundle exec puma \
  --environment development \
  --log-requests \
  --pidfile /app/openbel-api.pid \
  --port 9292 \
  --tag openbel-api-dev \
  --threads 1:2 \
  app/openbel/api/config.ru