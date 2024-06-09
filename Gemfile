source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '7.0.3'

gem 'chart-js-rails'
gem 'jsbundling-rails'
gem 'sassc-rails' # sass-rails replacent
gem 'terser' # ugilifer replacent

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
# gem 'duktape'

gem 'bootstrap', '~> 4.2.0'
gem 'jquery-rails'
gem 'jquery-ui-rails'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 5.0'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Reduces boot times through caching; required in config/boot.rb

gem 'bootsnap', require: false

gem 'cube-ruby', require: 'cube'
gem 'dalli'
gem 'ffi', '~> 1.16.3'
gem 'flag-icons-rails', '~> 3.4'
gem 'flamegraph'
gem 'graphql-client'
gem 'haml', '~> 5.1'
gem 'i18n'
gem 'iconv'
gem 'inline_svg'
gem 'iso-639', '~> 0.3.6'
gem 'lookbook', '~> 1.5.5'
gem 'multi_json'
gem 'mysql2'
gem 'oj'
gem 'ontologies_api_client', git: 'https://github.com/ontoportal-lirmm/ontologies_api_ruby_client.git',
                             branch: 'development'
gem 'open_uri_redirections'
gem 'pry'
gem 'psych', '< 4'
gem 'rack-mini-profiler'
gem 'rails_autolink'
gem 'rails-i18n', '~> 7.0.0'
gem 'rdoc'
gem 'recaptcha', '~> 5.9.0'
gem 'rest-client'
gem 'stackprof', require: false
gem 'thin'
gem 'turnout'
gem 'view_component', '~> 2.72'
gem 'will_paginate', '~> 3.0'

# Multi-Provider Authentication
gem 'omniauth'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'omniauth-keycloak'
gem 'omniauth-orcid'
gem 'omniauth-rails_csrf_protection'

group :staging, :production, :appliance do
  # application monitoring
  gem 'newrelic_rpm', '< 9.10.0'
  # logs in json format, useful for shipping logs to logstash
  # gem 'rackstash', git: 'https://github.com/planio-gmbh/rackstash.git'
  # gem 'logstash-logger'
end

group :development do
  # Capistrano Deployment
  gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0', require: false # https://github.com/miloserdow/capistrano-deploy/issues/42
  gem 'capistrano', '~> 3.11', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-locally', require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-yarn', require: false
  gem 'ed25519', '>= 1.2', '< 2.0', require: false # https://github.com/miloserdow/capistrano-deploy/issues/42
  gem 'html2haml'
  gem 'listen'
  # static code analysis
  gem 'brakeman', require: false
  gem 'rubocop', require: false
  # gem 'i18n-debug'
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw]

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'i18n-tasks'
  gem 'i18n-tasks-csv', '~> 1.1'
  gem 'web-console'

  gem 'deepl-rb'
  gem 'haml-rails'
  gem 'letter_opener_web', '~> 2.0'
end

group :test, :development do
  gem 'rspec-rails'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'simplecov-cobertura' # for codecov.io
  # gem 'webdrivers'
  gem 'webmock'
end

gem 'net-ftp', '~> 0.2.0', require: false
gem 'net-http', '~> 0.3.2'

gem 'bugsnag', '~> 6.26'
