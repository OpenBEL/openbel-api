#!/usr/bin/env bash
if [ $# != 1 ]; then
  echo "usage: siege.sh LOG" 1>&2
  exit 1
fi

OPTS="--benchmark --time=1m"
NUM_USERS=( 1 2 5 10 20 50 100 )
LOG="$1"
for n in "${NUM_USERS[@]}"; do
  thin -d start
  sleep 7s
  siege --benchmark --time=1m --concurrent=$n -f siege_urls --log=$LOG
  thin -d stop
done
