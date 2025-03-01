# frozen_string_literal: true

class ApplicationController < Sinatra::Base
  helpers ApplicationHelper

  before do
    content_type :json
  end

  error do
    { error: env['sinatra.error'].message }.to_json
  end

  # Root
  get '/' do
    json_response({ message: 'Welcome to the API!' })
  end
end
