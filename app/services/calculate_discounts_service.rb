# frozen_string_literal: true

class CalculateDiscountsService
  def initialize(user_id, positions)
    @user = User.with_pk!(user_id)
    @template = @user.template
    @positions = positions
    @products = preload_products
  end

  def call
    positions_details = calculate_positions_details
    total_sum = calculate_total_sum(positions_details)
    total_discount = calculate_total_discount(positions_details)
    total_cashback = calculate_total_cashback(positions_details)
    allow_write_off = calculate_allow_write_off(positions_details)

    format_result(total_sum, total_discount, total_cashback, allow_write_off, positions_details)
  end

  private

  # Предзагрузка всех товаров из базы
  def preload_products
    product_ids = @positions.map { |pos| pos[:id] }.uniq
    Product.where(id: product_ids).to_hash(:id)
  end

  # Расчет деталей позиций
  def calculate_positions_details
    @positions.map { |position| calculate_position(position) }.compact
  end

  # Расчет данных для отдельной позиции
  def calculate_position(position)
    product = fetch_product(position)
    return if product.nil? || product.type == 'noloyalty'

    total_price = calculate_total_price(position)
    discount_percent, cashback_percent = calculate_modifiers(product)

    build_position_details(product, total_price, discount_percent, cashback_percent)
  end

  # Реализация получения продукта
  def fetch_product(position)
    @products[position[:id]]
  end

  # Расчет общей стоимости позиции
  def calculate_total_price(position)
    position[:price].to_f * position[:quantity].to_i
  end

  # Вычисление модификаторов для продукта
  def calculate_modifiers(product)
    base_discount = @template.discount
    base_cashback = @template.cashback

    case @template.name.downcase
    when 'bronze'
      [0, calculate_cashback(product, base_cashback)]
    when 'silver'
      [calculate_discount(product, base_discount), calculate_cashback(product, base_cashback)]
    when 'gold'
      [calculate_discount(product, base_discount), 0]
    else
      [0, 0]
    end
  end

  # Расчет скидки
  def calculate_discount(product, base_discount)
    product.type == 'discount' ? base_discount + product.value.to_f : 0
  end

  # Расчет кэшбэка
  def calculate_cashback(product, base_cashback)
    product.type == 'increased_cashback' ? base_cashback + product.value.to_f : base_cashback
  end

  # Сбор информации о позиции в итоговой структуре
  def build_position_details(product, total_price, discount_percent, cashback_percent)
    discount_value = calculate_discount_value(total_price, discount_percent)
    final_price = calculate_final_price(total_price, discount_value)
    cashback_value = calculate_cashback_value(final_price, cashback_percent)

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
      allow_write_off: final_price.round(2)
    }
  end

  # Расчет значения скидки
  def calculate_discount_value(total_price, discount_percent)
    total_price * (discount_percent / 100.0)
  end

  # Расчет финальной стоимости
  def calculate_final_price(total_price, discount_value)
    total_price - discount_value
  end

  # Расчет итогового кэшбэка
  def calculate_cashback_value(final_price, cashback_percent)
    final_price * (cashback_percent / 100.0)
  end

  # Расчет итогов: суммарная стоимость
  def calculate_total_sum(positions_details)
    positions_details.sum { |pos| pos[:final_price] }
  end

  # Расчет итогов: суммарное значение скидки
  def calculate_total_discount(positions_details)
    positions_details.sum { |pos| pos[:discount_value] }
  end

  # Расчет итогов: суммарное значение кэшбэка
  def calculate_total_cashback(positions_details)
    positions_details.sum { |pos| pos[:cashback_value] }
  end

  # Расчет итогов: доступный к списанию кэшбэк
  def calculate_allow_write_off(positions_details)
    positions_details.sum { |pos| pos[:allow_write_off] }
  end

  # Форматирование результата
  def format_result(total_sum, total_discount, total_cashback, allow_write_off, positions_details)
    {
      user: {
        id: @user.id,
        name: @user.name,
        bonus: @user.bonus
      },
      positions: positions_details,
      total_sum: total_sum.round(2),
      discounts: {
        total_value: total_discount.round(2),
        total_percent: calculate_percent(total_discount, total_sum)
      },
      cashback: {
        total_value: total_cashback.round(2),
        total_percent: calculate_percent(total_cashback, total_sum)
      },
      allow_write_off: allow_write_off.round(2)
    }
  end

  # Общая логика для расчета процента
  def calculate_percent(part, whole)
    whole.positive? ? (part / whole * 100).round(2) : 0
  end
end
