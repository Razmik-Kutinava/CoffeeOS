class CreateStage5Stock < ActiveRecord::Migration[8.1]
  def up
    # Таблица ingredient_tenant_stock (остатки ингредиентов по точкам)
    create_table :ingredient_tenant_stocks, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :ingredient, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :qty, precision: 10, scale: 3, null: false, default: 0
      t.decimal :min_qty, precision: 10, scale: 3
      t.timestamp :last_updated_at, null: false, default: -> { "NOW()" }
      t.timestamps
    end
    
    add_index :ingredient_tenant_stocks, [:ingredient_id, :tenant_id], unique: true, name: 'idx_its_ingredient_tenant', if_not_exists: true
    add_index :ingredient_tenant_stocks, :ingredient_id, if_not_exists: true
    add_index :ingredient_tenant_stocks, :tenant_id, if_not_exists: true
    add_index :ingredient_tenant_stocks, [:tenant_id, :ingredient_id], where: "qty = 0", name: 'idx_its_zero_qty', if_not_exists: true
    
    execute <<-SQL
      ALTER TABLE ingredient_tenant_stocks
      ADD CONSTRAINT chk_stock_qty CHECK (qty >= 0)
    SQL
    
    execute "COMMENT ON TABLE ingredient_tenant_stocks IS 'Остатки ингредиентов по точкам'"
    
    # Таблица stock_movements (движения склада)
    create_table :stock_movements, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :movement_type, null: false, limit: 50 # receipt, write_off, inventory, order_deduct, return
      t.string :status, null: false, default: 'draft' # draft, confirmed, cancelled
      t.uuid :reference_id # ссылка на order_id для order_deduct
      t.text :note
      t.references :created_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :confirmed_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamp :confirmed_at
      t.timestamps
    end
    
    add_index :stock_movements, :tenant_id, if_not_exists: true
    add_index :stock_movements, :movement_type, if_not_exists: true
    add_index :stock_movements, :status, if_not_exists: true
    add_index :stock_movements, :reference_id, where: "reference_id IS NOT NULL", if_not_exists: true
    
    execute "COMMENT ON TABLE stock_movements IS 'Движения склада (приход, расход, инвентаризация)'"
    
    # Таблица stock_movement_items (позиции движения)
    create_table :stock_movement_items, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :movement, type: :uuid, null: false, foreign_key: { to_table: :stock_movements, on_delete: :cascade }
      t.references :ingredient, type: :uuid, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :qty_change, precision: 10, scale: 3, null: false
      t.decimal :unit_cost, precision: 10, scale: 2
      t.timestamps
    end
    
    add_index :stock_movement_items, :movement_id, if_not_exists: true
    add_index :stock_movement_items, :ingredient_id, if_not_exists: true
    
    execute "COMMENT ON TABLE stock_movement_items IS 'Позиции движения (какие ингредиенты, сколько)'"
    
    # Таблица product_recipes (рецептуры продуктов)
    create_table :product_recipes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :product, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :ingredient, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :qty_per_serving, precision: 10, scale: 3, null: false
      t.timestamps
    end
    
    add_index :product_recipes, [:product_id, :ingredient_id], unique: true, name: 'idx_recipes_product_ingredient', if_not_exists: true
    add_index :product_recipes, :product_id, if_not_exists: true
    add_index :product_recipes, :ingredient_id, if_not_exists: true
    
    execute <<-SQL
      ALTER TABLE product_recipes
      ADD CONSTRAINT chk_recipe_qty CHECK (qty_per_serving > 0)
    SQL
    
    execute "COMMENT ON TABLE product_recipes IS 'Рецептуры продуктов (сколько ингредиентов на 1 порцию)'"
    
    # Таблица modifier_option_recipes (как модификаторы влияют на рецептуру)
    create_table :modifier_option_recipes, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :option, type: :uuid, null: false, foreign_key: { to_table: :product_modifier_options, on_delete: :cascade }
      t.references :ingredient, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :qty_change, precision: 10, scale: 3, null: false
      t.timestamps
    end
    
    add_index :modifier_option_recipes, [:option_id, :ingredient_id], unique: true, name: 'idx_mor_option_ingredient', if_not_exists: true
    add_index :modifier_option_recipes, :option_id, if_not_exists: true
    add_index :modifier_option_recipes, :ingredient_id, if_not_exists: true
    
    execute "COMMENT ON TABLE modifier_option_recipes IS 'Как модификаторы влияют на рецептуру'"
    
    # Включаем RLS
    execute "ALTER TABLE ingredient_tenant_stocks ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE stock_movement_items ENABLE ROW LEVEL SECURITY"
    
    # RLS политики для ingredient_tenant_stocks
    execute <<-SQL
      CREATE POLICY rls_stock_isolation ON ingredient_tenant_stocks
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'office_manager', 'prep_kitchen_manager')
          )
        )
    SQL
    
    # RLS политики для stock_movements
    execute <<-SQL
      CREATE POLICY rls_stock_movements_isolation ON stock_movements
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для stock_movement_items (через stock_movement.tenant_id)
    execute <<-SQL
      CREATE POLICY rls_stock_movement_items_isolation ON stock_movement_items
        FOR ALL
        USING (
          EXISTS (
            SELECT 1 FROM stock_movements sm
            WHERE sm.id = stock_movement_items.movement_id
            AND sm.tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          )
        )
    SQL
  end
  
  def down
    execute "DROP POLICY IF EXISTS rls_stock_movement_items_isolation ON stock_movement_items"
    execute "DROP POLICY IF EXISTS rls_stock_movements_isolation ON stock_movements"
    execute "DROP POLICY IF EXISTS rls_stock_isolation ON ingredient_tenant_stocks"
    
    drop_table :modifier_option_recipes, if_exists: true
    drop_table :product_recipes, if_exists: true
    drop_table :stock_movement_items, if_exists: true
    drop_table :stock_movements, if_exists: true
    drop_table :ingredient_tenant_stocks, if_exists: true
  end
end
