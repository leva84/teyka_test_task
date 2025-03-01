# frozen_string_literal: true

class DiscountsController < ApplicationController
  get '/discounts/calculate' do
    json_response({ message: 'Welcome to the API!' })
  end
end
