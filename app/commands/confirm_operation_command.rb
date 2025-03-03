# frozen_string_literal: true

class ConfirmOperationCommand < BaseCommand
  def call
    validate_user
    return unless ok?

    fetch_operation
    return unless ok?

    validate_write_off
    return unless ok?

    process_confirmation
    format_response
  end

  private

  attr_reader :user, :operation

  def validate_user
    user_data = @args[:user]
    return add_error('User data is missing') unless user_data

    @user = User[user_data[:id]]

    unless user
      add_error("User with ID #{user_data[:id]} not found")
      return
    end

    return unless (user.bonus.to_f - user_data[:bonus].to_f).abs > 0.0001

    add_error('User bonus in request does not match database')
  end

  # Проверка существования операции
  def fetch_operation
    @operation = Operation[@args[:operation_id]]
    return add_error("Operation with ID #{ @args[:operation_id] } not found") unless operation

    add_error('Operation has already been confirmed') if operation.done
  end

  # Проверка валидности бонусов для списания
  def validate_write_off
    write_off = @args[:write_off].to_f

    if write_off > operation.allowed_write_off
      add_error(
        "Write-off exceeds allowed limits. Allowed: #{ operation.allowed_write_off.to_f }, Attempted: #{ write_off }"
      )
    elsif write_off > user.bonus
      add_error("User does not have enough bonus points. Available: #{ user.bonus.to_f }, Attempted: #{ write_off }")
    end
  end

  def process_confirmation
    write_off = @args[:write_off].to_f
    new_cashback = operation.cashback.to_f
    updated_bonus = user.bonus.to_f - write_off + new_cashback

    DB.transaction do
      user.update(bonus: updated_bonus)
      operation.update(
        write_off: write_off,
        done: true
      )
    end
  end

  def format_response
    @data_summary = {
      status: 200,
      message: 'Operation confirmed successfully',
      operation: {
        user_id: user.id,
        cashback: operation.cashback.to_f,
        cashback_percent: operation.cashback_percent.to_f,
        discount: operation.discount.to_f,
        discount_percent: operation.discount_percent.to_f,
        write_off: operation.write_off.to_f,
        check_summ: operation.check_summ.to_f
      }
    }
  end
end
