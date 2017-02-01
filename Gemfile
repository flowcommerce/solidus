# http is more reliable than https, keep
source 'http://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# basics
gem 'rails', '5.0.1'
gem 'puma'                     # we use this for dev and prod
gem 'pg'

gem 'dotenv', require: false
gem 'faraday', require: false

# solidus fw
gem 'solidus', '2.1.0'
gem 'solidus_auth_devise'

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'awesome_print'
  gem 'pry-rails'
  gem 'thread', require: false

  # css and js block
  gem 'therubyracer', platforms: :ruby
  gem 'sass-rails', '~> 5.0'
  gem 'uglifier', '>= 1.3.0'
  gem 'coffee-rails', '~> 4.2'
  gem 'turbolinks', '~> 5'
  gem 'smarter_csv'
end

group :production do
  gem 'newrelic_rpm'
  gem 'rack-timeout', require: 'rack/timeout/base' # Rack::Timeout is important for avoiding stuck Puma workers/threads on server:
end

# group :development, :test do
#   gem 'byebug', platform: :mri     # Call 'byebug' anywhere in the code to stop execution and get a debugger console
#   gem 'web-console', '>= 3.3.0'    # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
# end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# anyone uses windows? uncomment and commit
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
