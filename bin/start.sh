#!/usr/bin/env bash

# migrate if needed
bunle exec rake db:migrate

# run web server
puma -p 3000 -e production &

while true
do
  # sleep, then recheck if sync is needed
  sleep 90

  # refresh DB
  bundle exec rake flow:sync_localized_items

  # inform that refresh happend
  curl -fsS --retry 3 https://hchk.io/93912c0e-65cd-4f5b-a912-8983448f370b > /dev/null
done
