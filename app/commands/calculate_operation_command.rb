# frozen_string_literal: true

class CalculateOperationCommand < BaseCommand
  def call
    validate_user
    validate_positions

    return unless ok?

    fetch_products
    calculate_discounts_and_cashbacks

    @data_summary = format_response
  end

  private

  def positions
    @positions ||= args[:positions]
  end

  def validate_user
    @user = User.with_pk(args[:user_id])
    add_error("User with ID #{args[:user_id]} not found") unless @user
  end

  def validate_positions
    add_error('Positions are required and should be an array') if positions.nil? || !positions.is_a?(Array) || positions.empty?

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

  def fetch_products
    product_ids = args[:positions].map { |position| position[:id] }
    @products = Product.where(id: product_ids).to_hash(:id)
  end

  def calculate_discounts_and_cashbacks
    @positions_details = []
    @total_discount = 0.0
    @total_cashback = 0.0
    @total_sum = 0.0

    args[:positions].each do |position|
      product = @products[position[:id]]

      if product.nil?
        # Продукт не найден, добавляем ошибочную позицию
        @positions_details << position.merge(
          type: nil,
          value: nil,
          type_desc: 'Product not found',
          discount_percent: 0.0,
          discount_summ: 0.0
        )
        next
      end

      # Расчеты по продукту для позиции
      total_price = position[:price].to_f * position[:quantity].to_i
      discount_percent, discount_summ = calculate_discount(product, total_price)
      cashback_percent, cashback_summ = calculate_cashback(product, total_price, discount_summ)

      @total_discount += discount_summ
      @total_cashback += cashback_summ
      @total_sum += total_price - discount_summ

      # Добавляем результат по позиции
      @positions_details << position.merge(
        type: product[:type],
        value: product[:value],
        type_desc: product[:description],
        discount_percent: discount_percent,
        discount_summ: discount_summ
      )
    end
  end

  def calculate_discount(product, total_price)
    discount_percent = product[:type] == 'discount' ? product[:value].to_f : 0.0
    discount_summ = (total_price * discount_percent / 100).round(2)
    [discount_percent, discount_summ]
  end

  def calculate_cashback(product, total_price, discount_summ)
    return [0.0, 0.0] if product[:type] == 'noloyalty'

    cashback_percent = product[:type] == 'increased_cashback' ? product[:value].to_f : base_cashback_percent
    final_price = total_price - discount_summ
    cashback_summ = (final_price * cashback_percent / 100).round(2)
    [cashback_percent, cashback_summ]
  end

  def calculate_allow_write_off
    @positions_details
      .reject { |position| position[:type] == 'noloyalty' }
      .sum { |position| position[:price].to_f * position[:quantity].to_i }
  end

  def format_response
    write_off_limit = calculate_allow_write_off
    bonus_to_add = @total_cashback.round

    {
      status: 200,
      user: {
        id: @user.id,
        template_id: @user.template_id,
        name: @user.name,
        bonus: @user.bonus.to_s
      },
      operation_id: generate_operation_id,
      summ: @total_sum.round(2),
      positions: @positions_details,
      discount: {
        summ: @total_discount.round(2),
        value: "#{ calculate_percent(@total_discount, @total_sum + @total_discount) }%"
      },
      cashback: {
        existed_summ: @user.bonus.to_f,
        allowed_summ: write_off_limit.round(2),
        value: "#{ calculate_percent(@total_cashback, @total_sum + @total_discount) }%",
        will_add: bonus_to_add
      }
    }
  end

  def generate_operation_id
    operation = Operation.create(
      user_id: @user.id,
      check_summ: @total_sum, # Общая сумма чека
      discount: @total_discount, # Общая сумма скидки
      discount_percent: calculate_percent(@total_discount, @total_sum + @total_discount), # Общий процент скидки
      cashback: @total_cashback, # Общая сумма кэшбэка
      cashback_percent: calculate_percent(@total_cashback, @total_sum + @total_discount), # Общий процент кэшбэка
      allowed_write_off: calculate_allow_write_off, # Разрешённая сумма списания бонусов
      write_off: 0, # Это значение по умолчанию (пока списание не используется)
      done: false # Флаг выполнения операции
    )
    operation.id
  rescue StandardError => e
    add_error("Error while saving operation: #{ e.message }")
    code(value: 500)
    nil
  end

  def calculate_percent(part, whole)
    whole.zero? ? 0.0 : ((part / whole) * 100).round(2)
  end

  def base_cashback_percent
    case @user.template_id
    when 1 then 5.0  # Bronze
    when 2 then 3.0  # Silver
    when 3 then 0.0  # Gold
    else 0.0
    end
  end
end
