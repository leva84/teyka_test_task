# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.6'
gem 'sinatra'

# Locales
gem 'i18n'
# Service Puma
gem 'puma'
# Rack Manager
gem 'rackup'
# Sequel ORM
gem 'sequel'
# SQLite3 connector
gem 'sqlite3'

group :development, :test do
  # Debugging
  gem 'pry'
end

group :development do
  gem 'rubocop', require: false
end

group :test do
  gem 'rspec'
  # Testing Sinatra requests
  gem 'rack-test'
  # Cleaning DB
  gem 'database_cleaner-sequel'
end
