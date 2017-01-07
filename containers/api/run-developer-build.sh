#!/usr/bin/env bash

cd /app

bundle install --system

if [ -z "$RACK_ENV" ]; then
  export RACK_ENV=development
fi

exec jruby -S bundle exec puma \
  --log-requests \
  --pidfile /app/openbel-api.pid \
  --port 9292 \
  --tag openbel-api-dev \
  --threads 1:2 \
  app/openbel/api/config.ru
