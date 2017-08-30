#!/usr/bin/env ruby

require 'pathname'
require 'json'
require './app/flow_io/lib/flow_api_refresh'

FolwApiRefresh.sync_products_if_needed!