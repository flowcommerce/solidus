#!/usr/bin/env bash

# migrate if needed
bunle exec rake db:migrate

# run web server
puma -p 3000 -e production &

while true
do
  # sleep, then recheck if sync is needed
  sleep 120

  # refresh DB
  bundle exec rake flow:sync_localized_items
done
