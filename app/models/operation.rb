class Operation < Sequel::Model
  many_to_one :user # Связь many-to-one с таблицей users

  # Валидации
  def validate
    super
    validates_presence %i[user_id cashback cashback_percent discount discount_percent check_summ]
    validates_numeric %i[cashback cashback_percent discount discount_percent check_summ]
    validates_numeric %i[write_off allowed_write_off]
    validates_includes [true, false], :done # Проверка на значение true/false для boolean
  end
end
