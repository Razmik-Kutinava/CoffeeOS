class CreateStage3Products < ActiveRecord::Migration[8.1]
  def up
    # Таблица categories (категории)
    create_table :categories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false, limit: 255
      t.string :slug, null: false, limit: 150
      t.text :description
      t.integer :sort_order, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      t.references :created_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    
    add_index :categories, :slug, unique: true, if_not_exists: true
    add_index :categories, :is_active, if_not_exists: true
    add_index :categories, :sort_order, if_not_exists: true
    
    execute "COMMENT ON TABLE categories IS 'Категории продуктов (Кофе, Чай, Десерты)'"
    
    # Таблица products (продукты)
    create_table :products, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :category, type: :uuid, null: false, foreign_key: { on_delete: :restrict }
      t.string :name, null: false, limit: 255
      t.string :slug, null: false, limit: 150
      t.text :description
      t.decimal :base_price, precision: 10, scale: 2
      t.string :image_url, limit: 500
      t.integer :sort_order, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      t.references :created_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :copied_from, type: :uuid, null: true, foreign_key: { to_table: :products, on_delete: :nullify }
      t.timestamps
    end
    
    add_index :products, :slug, unique: true, if_not_exists: true
    add_index :products, :category_id, if_not_exists: true
    add_index :products, :is_active, if_not_exists: true
    add_index :products, :sort_order, if_not_exists: true
    
    execute "COMMENT ON TABLE products IS 'Глобальный каталог продуктов (управляет УК)'"
    execute "COMMENT ON COLUMN products.base_price IS 'Базовая цена (рекомендованная), точки могут переопределять'"
    
    # Таблица product_modifier_groups (группы модификаторов)
    create_table :product_modifier_groups, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :product, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false, limit: 100
      t.boolean :is_required, default: false, null: false
      t.integer :sort_order, default: 0, null: false
      t.timestamps
    end
    
    add_index :product_modifier_groups, :product_id, if_not_exists: true
    add_index :product_modifier_groups, :sort_order, if_not_exists: true
    
    execute "COMMENT ON TABLE product_modifier_groups IS 'Группы модификаторов (Размер, Молоко, Сироп)'"
    
    # Таблица product_modifier_options (опции модификаторов)
    create_table :product_modifier_options, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :group, type: :uuid, null: false, foreign_key: { to_table: :product_modifier_groups, on_delete: :cascade }
      t.string :name, null: false, limit: 100
      t.decimal :price_delta, precision: 10, scale: 2, null: false, default: 0
      t.boolean :is_active, default: true, null: false
      t.integer :sort_order, default: 0, null: false
      t.timestamps
    end
    
    add_index :product_modifier_options, :group_id, if_not_exists: true
    add_index :product_modifier_options, :is_active, if_not_exists: true
    add_index :product_modifier_options, :sort_order, if_not_exists: true
    
    execute "COMMENT ON TABLE product_modifier_options IS 'Опции модификаторов (S/M/L, Обычное/Овсяное)'"
    
    # Таблица modifier_option_tenant_settings (локальные наценки на модификаторы)
    create_table :modifier_option_tenant_settings, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :option, type: :uuid, null: false, foreign_key: { to_table: :product_modifier_options, on_delete: :cascade }
      t.decimal :price_delta_override, precision: 10, scale: 2, null: false
      t.references :updated_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    
    add_index :modifier_option_tenant_settings, [:tenant_id, :option_id], unique: true, name: 'idx_mots_tenant_option', if_not_exists: true
    add_index :modifier_option_tenant_settings, :tenant_id, if_not_exists: true
    add_index :modifier_option_tenant_settings, :option_id, if_not_exists: true
    
    execute "COMMENT ON TABLE modifier_option_tenant_settings IS 'Локальные наценки на модификаторы по точкам'"
    
    # Таблица product_tenant_settings (цены и стоп-лист по точкам)
    create_table :product_tenant_settings, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :product, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :price, precision: 10, scale: 2
      t.boolean :is_enabled, default: true, null: false
      t.boolean :is_sold_out, default: false, null: false
      t.string :sold_out_reason, limit: 50 # manual, stock_empty
      t.decimal :stock_qty, precision: 10, scale: 3
      t.references :price_updated_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    
    add_index :product_tenant_settings, [:product_id, :tenant_id], unique: true, name: 'idx_pts_product_tenant', if_not_exists: true
    add_index :product_tenant_settings, :product_id, if_not_exists: true
    add_index :product_tenant_settings, :tenant_id, if_not_exists: true
    add_index :product_tenant_settings, [:tenant_id, :is_enabled, :is_sold_out], name: 'idx_pts_tenant_enabled', if_not_exists: true
    
    execute <<-SQL
      ALTER TABLE product_tenant_settings
      ADD CONSTRAINT chk_sold_out_reason CHECK (
        (is_sold_out = FALSE AND sold_out_reason IS NULL) OR
        (is_sold_out = TRUE AND sold_out_reason IN ('manual', 'stock_empty'))
      )
    SQL
    
    execute "COMMENT ON TABLE product_tenant_settings IS 'Настройки продукта для конкретной точки'"
    execute "COMMENT ON COLUMN product_tenant_settings.sold_out_reason IS 'manual или stock_empty (автостоп)'"
    
    # Таблица menu_types (типы меню)
    create_table :menu_types, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :code, null: false, limit: 50
      t.string :name, null: false, limit: 100
      t.text :description
      t.timestamps
    end
    
    add_index :menu_types, :code, unique: true, if_not_exists: true
    
    execute "COMMENT ON TABLE menu_types IS 'Типы меню (kiosk, main, seasonal)'"
    
    # Таблица product_menu_visibility (видимость продуктов в разных меню)
    create_table :product_menu_visibilities, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :product, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :menu_type, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :is_visible, default: true, null: false
      t.timestamps
    end
    
    add_index :product_menu_visibilities, [:product_id, :menu_type_id], unique: true, name: 'idx_pmv_product_menu', if_not_exists: true
    add_index :product_menu_visibilities, :product_id, if_not_exists: true
    add_index :product_menu_visibilities, :menu_type_id, if_not_exists: true
    
    execute "COMMENT ON TABLE product_menu_visibilities IS 'Видимость продуктов в разных меню'"
    
    # Таблица product_price_history (история изменения цен)
    create_table :product_price_histories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :product, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :price_old, precision: 10, scale: 2
      t.decimal :price_new, precision: 10, scale: 2, null: false
      t.references :changed_by, type: :uuid, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    
    add_index :product_price_histories, :tenant_id, if_not_exists: true
    add_index :product_price_histories, :product_id, if_not_exists: true
    add_index :product_price_histories, :created_at, order: { created_at: :desc }, if_not_exists: true
    
    execute "COMMENT ON TABLE product_price_histories IS 'История изменения цен продуктов по точкам'"
    
    # Включаем RLS
    execute "ALTER TABLE modifier_option_tenant_settings ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE product_tenant_settings ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE product_price_histories ENABLE ROW LEVEL SECURITY"
    
    # RLS политики для modifier_option_tenant_settings
    execute <<-SQL
      CREATE POLICY rls_mots_isolation ON modifier_option_tenant_settings
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # RLS политики для product_tenant_settings
    execute <<-SQL
      CREATE POLICY rls_pts_isolation ON product_tenant_settings
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
          OR EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN roles r ON ur.role_id = r.id
            WHERE ur.user_id = NULLIF(current_setting('app.current_user_id', TRUE), '')::UUID
            AND r.code IN ('ук_global_admin', 'office_manager')
          )
        )
    SQL
    
    # RLS политики для product_price_histories
    execute <<-SQL
      CREATE POLICY rls_product_price_histories_isolation ON product_price_histories
        FOR ALL
        USING (
          tenant_id = NULLIF(current_setting('app.current_tenant_id', TRUE), '')::UUID
        )
    SQL
    
    # Добавляем foreign key для order_items.product_id -> products.id
    # (таблица order_items создана в миграции этапа 1, но foreign key не был добавлен)
    execute <<-SQL
      ALTER TABLE order_items
      ADD CONSTRAINT fk_order_items_product
      FOREIGN KEY (product_id)
      REFERENCES products(id)
      ON DELETE RESTRICT;
    SQL
  end
  
  def down
    execute "DROP POLICY IF EXISTS rls_product_price_histories_isolation ON product_price_histories"
    execute "DROP POLICY IF EXISTS rls_pts_isolation ON product_tenant_settings"
    execute "DROP POLICY IF EXISTS rls_mots_isolation ON modifier_option_tenant_settings"
    
    drop_table :product_price_histories, if_exists: true
    drop_table :product_menu_visibilities, if_exists: true
    drop_table :menu_types, if_exists: true
    drop_table :product_tenant_settings, if_exists: true
    drop_table :modifier_option_tenant_settings, if_exists: true
    drop_table :product_modifier_options, if_exists: true
    drop_table :product_modifier_groups, if_exists: true
    # Удаляем foreign key перед удалением таблицы
    execute "ALTER TABLE order_items DROP CONSTRAINT IF EXISTS fk_order_items_product"
    
    drop_table :products, if_exists: true
    drop_table :categories, if_exists: true
  end
end
