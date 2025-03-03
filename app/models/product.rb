# frozen_string_literal: true

class Product < Sequel::Model
  MODIFIERS = {
    discount: 'discount',
    increased_cashback: 'increased_cashback',
    noloyalty: 'noloyalty'
  }.freeze

  plugin :validation_helpers

  # Валидации
  def validate
    super
    validates_presence %i[name]
    validates_includes MODIFIERS.values, :type, message: 'Invalid product type'
  end
end
