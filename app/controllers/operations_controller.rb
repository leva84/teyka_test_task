# frozen_string_literal: true

class OperationsController < ApplicationController
  get '/operation' do
    json_response({ message: 'Welcome to the API!' })
  end
end
