# frozen_string_literal: true

class Product < Sequel::Model
  plugin :validation_helpers

  # Валидации
  def validate
    super
    validates_presence %i[name]
  end
end
