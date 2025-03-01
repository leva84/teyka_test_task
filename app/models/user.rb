# frozen_string_literal: true

class User < Sequel::Model
  plugin :validation_helpers
  many_to_one :template # Связь many-to-one с таблицей templates
  one_to_many :operations # Связь one-to-many с таблицей operations

  # Валидации
  def validate
    super
    validates_presence %i[name template_id]
    validates_numeric :bonus
  end
end
