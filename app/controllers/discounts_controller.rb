# frozen_string_literal: true

class DiscountsController < ApplicationController
  get '/submit' do
    json_response({ message: 'Welcome to the API!' })
  end
end
