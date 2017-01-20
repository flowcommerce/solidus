source 'https://rubygems.org'
ruby '2.2.5'

# New Relic plugin
gem 'newrelic_rpm'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.6'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.15'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Rack::Timeout is important for avoiding stuck Puma workers/threads on server:
gem 'rack-timeout', require: 'rack/timeout/base'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'solidus', '~> 1.3'
gem 'solidus_auth_devise', '~> 1.5'

gem 'bourbon'
gem 'neat'

gem 'colorize'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug"
  gem "awesome_print"
  gem "better_errors"
  gem "binding_of_caller"
  gem "dotenv-rails"
  gem "factory_girl_rails"
  gem "ffaker"
  gem "i18n-tasks"
  gem "pry-byebug"
  gem "pry-rails"
  gem "pry-remote"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # SCSS Lint is used for linting stylesheets:
  gem 'scss_lint', require: false
end

group :test do
  gem "rspec-rails"
  gem "capybara"
  gem "capybara-screenshot"
  gem "database_cleaner"
  gem "launchy"
  gem "poltergeist"
  gem "simplecov", :require => false
end

group :production do
  # Setup STDOUT logging, and dev/prod asset handling parity (recommended by
  # Heroku) with rails_12factor:
  gem 'rails_12factor'
end

# Use Puma as the app server
gem 'puma'

gem 'httpclient'
gem 'faraday'
gem "smarter_csv"

gem "aws-sdk", "< 2.0"
