# frozen_string_literal: true

module ApplicationHelper
  def json_response(data, status = 200)
    halt status, data.to_json
  end

  def safe_params
    JSON.parse(request.body.read, symbolize_names: true)
  rescue JSON::ParserError
    json_response(
      { error: 'Invalid JSON format in request' },
      400
    )
  end
end
