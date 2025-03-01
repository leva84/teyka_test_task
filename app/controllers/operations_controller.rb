# frozen_string_literal: true

class OperationsController < ApplicationController
  get '/operations/confirm' do
    json_response({ message: 'Welcome to the API!' })
  end
end
