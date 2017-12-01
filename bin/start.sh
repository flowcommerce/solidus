#!/usr/bin/env bash

bunle exec rake db:migrate
puma -p 3000 -e production
