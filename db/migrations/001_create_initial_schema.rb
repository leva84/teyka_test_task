Sequel.migration do
  change do
    # Таблица templates
    create_table(:templates) do
      primary_key :id
      String :name, null: false, size: 255
      Integer :discount, null: false
      Integer :cashback, null: false
    end

    # Индекс для templates
    add_index :templates, :id, unique: true

    # Таблица users
    create_table(:users) do
      primary_key :id
      foreign_key :template_id, :templates, null: false, on_delete: :cascade
      String :name, null: false, size: 255
      BigDecimal :bonus, size: [10, 2] # numeric column in SQL
    end

    # Индекс для users
    add_index :users, :id, unique: true

    # Таблица products
    create_table(:products) do
      primary_key :id
      String :name, null: false, size: 255
      String :type, size: 255
      String :value, size: 255
    end

    # Индекс для products
    add_index :products, :id, unique: true

    # Таблица operations
    create_table(:operations) do
      primary_key :id
      foreign_key :user_id, :users, null: false, on_delete: :cascade
      BigDecimal :cashback, null: false, size: [10, 2]
      BigDecimal :cashback_percent, null: false, size: [10, 2]
      BigDecimal :discount, null: false, size: [10, 2]
      BigDecimal :discount_percent, null: false, size: [10, 2]
      BigDecimal :write_off, size: [10, 2]
      BigDecimal :check_summ, null: false, size: [10, 2]
      Boolean :done, default: false
      BigDecimal :allowed_write_off, size: [10, 2]
    end

    # Индекс для operations
    add_index :operations, :id, unique: true
  end
end
