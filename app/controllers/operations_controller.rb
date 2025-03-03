# frozen_string_literal: true

class OperationsController < ApplicationController
  post '/operation' do
    params = safe_params
    command = CalculateOperationCommand.call(
      user_id: params[:user_id],
      positions: params[:positions]
    )

    if command.ok?
      json_response(command.data_summary, command.code)
    else
      json_response({ errors: command.errors }, command.code)
    end
  end
end
