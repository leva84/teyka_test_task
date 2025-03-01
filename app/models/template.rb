# frozen_string_literal: true

class Template < Sequel::Model
  one_to_many :users # Связь one-to-many с таблицей users

  # Валидации
  def validate
    super
    validates_presence %i[name discount cashback]
    validates_integer %i[discount cashback]
  end
end
