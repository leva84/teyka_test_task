# frozen_string_literal: true

class CalculateDiscountsService
  def initialize(user_id, positions)
    @user = User.with_pk!(user_id)
    @template = @user.template
    @positions = positions
  end

  def call
    # Предзагружаем все продукты разом
    product_ids = @positions.map { |position| position[:id] }.uniq
    products = Product.where(id: product_ids).to_hash(:id)

    total_sum = 0
    total_discount = 0
    total_cashback = 0
    allow_write_off = 0
    positions_details = []

    @positions.each do |position|
      # Берем товар из предзагруженного хэш-мэппа
      product = products[position[:id]]
      next if product.nil? || product.type == 'noloyalty'

      # Вычисляем скидки/кэшбек
      result = process_position(product, position)

      # Суммируем результаты
      total_sum += result[:final_price]
      total_discount += result[:discount_value]
      total_cashback += result[:cashback_value]
      allow_write_off += result[:allow_write_off]

      positions_details << result # Добавляем данные о позиции
    end

    format_result(total_sum, total_discount, total_cashback, allow_write_off, positions_details)
  end

  private

  def process_position(product, position)
    price = position[:price].to_f
    quantity = position[:quantity].to_i
    total_price = price * quantity

    # Рассчитываем проценты скидок и кэшбека для товара
    discount_percent, cashback_percent = calculate_modifiers(product)

    # Рассчитываем абсолютные значения
    discount_value = total_price * (discount_percent / 100.0)
    cashback_value = (total_price - discount_value) * (cashback_percent / 100.0)
    final_price = total_price - discount_value

    {
      product_id: product.id,
      name: product.name,
      type: product.type,
      original_price: total_price.round(2),
      final_price: final_price.round(2),
      discount_value: discount_value.round(2),
      cashback_value: cashback_value.round(2),
      discount_percent: discount_percent,
      cashback_percent: cashback_percent,
      allow_write_off: final_price # Это значение доступно для списания
    }
  end

  def calculate_modifiers(product)
    base_discount = @template.discount
    base_cashback = @template.cashback

    case @template.name.downcase
    when 'bronze'
      [0, base_cashback + (product.type == 'increased_cashback' ? product.value.to_f : 0)]
    when 'silver'
      discount = product.type == 'discount' ? base_discount + product.value.to_f : 0
      cashback = product.type == 'increased_cashback' ? base_cashback + product.value.to_f : base_cashback
      [discount, cashback]
    when 'gold'
      discount = product.type == 'discount' ? base_discount + product.value.to_f : base_discount
      [discount, 0]
    else
      [0, 0]
    end
  end

  def format_result(total_sum, total_discount, total_cashback, allow_write_off, positions_details)
    {
      user: {
        id: @user.id,
        name: @user.name,
        bonus: @user.bonus
      },
      positions: positions_details, # Детализированная информация по позициям
      total_sum: total_sum.round(2),
      discounts: {
        total_value: total_discount.round(2),
        total_percent: total_sum.positive? ? (total_discount / total_sum * 100).round(2) : 0
      },
      cashback: {
        total_value: total_cashback.round(2),
        total_percent: total_sum.positive? ? (total_cashback / total_sum * 100).round(2) : 0
      },
      allow_write_off: allow_write_off.round(2)
    }
  end
end
