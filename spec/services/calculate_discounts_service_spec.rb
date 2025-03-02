# frozen_string_literal: true

describe CalculateDiscountsService do
  let(:bronze_template) { Template.create(name: 'Bronze', discount: 0, cashback: 5) }
  let(:silver_template) { Template.create(name: 'Silver', discount: 10, cashback: 5) }
  let(:gold_template)   { Template.create(name: 'Gold', discount: 15, cashback: 0) }

  let(:user_bronze) { User.create(name: 'User Bronze', template: bronze_template, bonus: 200) }
  let(:user_silver) { User.create(name: 'User Silver', template: silver_template, bonus: 300) }
  let(:user_gold)   { User.create(name: 'User Gold', template: gold_template, bonus: 500) }

  let(:product_discount) { Product.create(name: 'Product A', type: 'discount', value: '10') }
  let(:product_cashback) { Product.create(name: 'Product B', type: 'increased_cashback', value: '7') }
  let(:product_noloyalty) { Product.create(name: 'Product C', type: 'noloyalty') }

  context 'when user has Bronze level' do
    let(:positions) do
      [
        { id: product_discount.id, price: 100, quantity: 1 },
        { id: product_cashback.id, price: 50, quantity: 2 }
      ]
    end
    let(:service) { described_class.new(user_bronze.id, positions) }
    let(:result) { service.call }

    it 'does not apply discounts but calculates cashback correctly' do
      # Сумма: 100 (Product A) + 100 (Product B)
      total_price = 100 + (50 * 2)

      # Cashback: базовый кэшбек 5% на все + 7% для Product B
      expected_cashback = ((total_price * 0.05) + (50 * 2 * 0.07)).round(2)

      expect(result[:total_sum]).to eq(total_price)
      expect(result[:cashback][:total_value]).to eq(expected_cashback)
      expect(result[:discounts][:total_value]).to eq(0) # Скидок нет для Bronze
    end
  end

  context 'when user has Silver level' do
    let(:positions) do
      [
        { id: product_discount.id, price: 100, quantity: 2 },
        { id: product_cashback.id, price: 50, quantity: 1 }
      ]
    end
    let(:service) { described_class.new(user_silver.id, positions) }
    let(:result) { service.call }

    it 'calculates correct discounts and cashback' do
      expect(result[:total_sum]).to be > 0
      expect(result[:discounts][:total_value]).to eq(40.0)
      expect(result[:cashback][:total_value]).to eq(14.0)
    end
  end

  context 'when user has Gold level' do
    let(:positions) do
      [
        { id: product_discount.id, price: 200, quantity: 1 },
        { id: product_cashback.id, price: 100, quantity: 1 }
      ]
    end
    let(:service) { described_class.new(user_gold.id, positions) }
    let(:result) { service.call }

    it 'applies only discounts, without calculating cashback' do
      # Расчет скидки для Product A
      base_discount = 200 * 0.15 # 15% базовая скидка
      additional_discount = 200 * 0.10 # 10% от модификатора
      total_discount_product_a = base_discount + additional_discount # Итоговая скидка для A
      final_price_product_a = 200 - total_discount_product_a # Итоговая цена после скидки

      # Цена Product B остается без изменений
      final_price_product_b = 100

      # Общая сумма
      expected_total_sum = final_price_product_a + final_price_product_b # 150 + 100 = 250

      # Проверки
      expect(result[:total_sum]).to eq(expected_total_sum)
      expect(result[:discounts][:total_value]).to eq(total_discount_product_a) # Только для Product A
      expect(result[:cashback][:total_value]).to eq(0) # Gold не получает кэшбэк
    end
  end

  context 'when product is noloyalty' do
    let(:positions) do
      [
        { id: product_noloyalty.id, price: 100, quantity: 1 }
      ]
    end
    let(:service) { described_class.new(user_silver.id, positions) }
    let(:result) { service.call }

    it 'does not include noloyalty products in cashback or discounts' do
      expect(result[:discounts][:total_value]).to eq(0)
      expect(result[:cashback][:total_value]).to eq(0)
      expect(result[:allow_write_off]).to eq(0)
    end
  end
end
