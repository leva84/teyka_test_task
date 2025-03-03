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

  post '/confirm' do
    params = safe_params
    command = ConfirmOperationCommand.call(
      user: params[:user],
      operation_id: params[:operation_id],
      write_off: params[:write_off]
    )

    if command.ok?
      json_response(command.data_summary, command.code)
    else
      json_response({ errors: command.errors }, command.code)
    end
  end
end
