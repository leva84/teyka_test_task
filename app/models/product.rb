# frozen_string_literal: true

class Product < Sequel::Model
  # Валидации
  def validate
    super
    validates_presence %i[name]
  end
end
