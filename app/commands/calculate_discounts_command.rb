# frozen_string_literal: true

class CalculateDiscountsCommand < BaseCommand
  attr_reader :user

  # Основной метод вызова команды
  def call
    # Валидация данных
    validate_params
    return unless ok?

    # Загрузка пользователя
    fetch_user
    return unless ok?

    # Вызываем сервис
    result = calculate_discounts_and_bonuses
    return unless ok?

    # Сохраняем операцию
    operation_id = save_operation(result)
    return unless ok?

    # Формируем результат
    @data_summary = format_response(result, operation_id)
  end

  private

  # Валидация входных параметров
  def validate_params
    validate_user
    validate_positions
  end

  def validate_user
    user_id = args[:user_id]
    add_error('User ID is required') if user_id.nil? || user_id.to_s.strip.empty?
  end

  def validate_positions
    positions = args[:positions]
    return add_error('Positions are required and should be an array') if positions.nil? || !positions.is_a?(Array)

    positions.each do |pos|
      if pos[:id].nil? || pos[:price].nil? || pos[:quantity].nil?
        add_error('Each position must have id, price, and quantity')
        break
      end

      if pos[:id].negative? || pos[:price].negative? || pos[:quantity].negative?
        add_error('Each position should have ID, prices and quantity of a lot of zero')
        break
      end
    end
  end

  # Загрузка пользователя
  def fetch_user
    @user = User.with_pk(args[:user_id])
    add_error("User with ID #{ args[:user_id] } not found") if @user.nil?
  end

  # Вызов сервиса для расчетов
  def calculate_discounts_and_bonuses
    service = CalculateDiscountsService.new(@user.id, args[:positions])
    result = service.call
    add_error('Error during discount calculation: result empty') if result.nil?
    result
  rescue StandardError => e
    add_error("Error during discount calculation: #{ e.message }")
    code(value: 500)
    nil
  end

  # Сохранение операции
  def save_operation(result)
    operation = Operation.create(
      user_id: @user.id,
      check_summ: result[:total_sum], # Общая сумма чека
      discount: result[:discounts][:total_value], # Общая сумма скидки
      discount_percent: result[:discounts][:total_percent], # Общий процент скидки
      cashback: result[:cashback][:total_value], # Общая сумма кэшбэка
      cashback_percent: result[:cashback][:total_percent], # Общий процент кэшбэка
      allowed_write_off: result[:allow_write_off], # Разрешенная сумма списания баллов
      write_off: 0, # Здесь используется значение по умолчанию или расчетное значение
      done: false # Необходим ли флаг выполнения (по умолчанию false)
    )
    operation.id
  rescue StandardError => e
    add_error("Error while saving operation: #{e.message}")
    code(value: 500)
    nil
  end

  # Формирование ответа
  def format_response(result, operation_id)
    {
      status: 'success',
      user: {
        id: @user.id,
        name: @user.name,
        bonus_balance: @user.bonus,
        allow_write_off: result[:allow_write_off]
      },
      operation_id: operation_id,
      total_sum: result[:total_sum],
      bonuses: {
        current_balance: @user.bonus,
        allow_write_off: result[:allow_write_off],
        cashback_percent: result[:cashback][:total_percent],
        cashback_value: result[:cashback][:total_value]
      },
      discounts: {
        total_value: result[:discounts][:total_value],
        total_percent: result[:discounts][:total_percent]
      },
      positions: format_positions(result[:positions])
    }
  end

  # Форматирование позиций для ответа
  def format_positions(positions)
    positions.map do |pos|
      {
        product_id: pos[:product_id],
        name: pos[:name],
        type: pos[:type],
        original_price: pos[:original_price],
        final_price: pos[:final_price],
        discount_percent: pos[:discount_percent],
        discount_value: pos[:discount_value],
        cashback_percent: pos[:cashback_percent],
        cashback_value: pos[:cashback_value],
        description: "Loyalty Type: #{pos[:type]}"
      }
    end
  end
end
