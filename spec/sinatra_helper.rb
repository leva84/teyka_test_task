# frozen_string_literal: true

require 'spec_helper'
ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'rspec'
require 'database_cleaner-sequel'
require_relative '../config/application'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    TeykaApp
  end

  config.before(:suite) do
    DatabaseCleaner[:sequel].strategy = :transaction
    DatabaseCleaner[:sequel].clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner[:sequel].cleaning do
      example.run
    end
  end

  config.order = :random
  Kernel.srand config.seed
end
