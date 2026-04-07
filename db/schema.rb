# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_06_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "order_source", ["kiosk", "app", "manual", "mobile"]
  create_enum "order_status", ["pending_payment", "accepted", "preparing", "ready", "issued", "closed", "cancelled"]
  create_enum "payment_method", ["card", "cash", "sbp", "apple_pay", "google_pay", "internal_balance", "mixed"]
  create_enum "payment_status", ["pending", "processing", "succeeded", "failed", "refunded", "partially_refunded", "requires_review"]
  create_enum "shift_status", ["open", "closed", "cancelled"]

  create_table "blog_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_blog_categories_on_slug", unique: true
  end

  create_table "blog_posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blog_category_id"
    t.text "body"
    t.text "conclusion"
    t.string "cover_image_url", limit: 2048
    t.datetime "created_at", null: false
    t.text "intro"
    t.string "meta_description", limit: 500
    t.string "meta_title"
    t.integer "position", default: 0, null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_category_id"], name: "index_blog_posts_on_blog_category_id"
    t.index ["published_at"], name: "index_blog_posts_on_published_at"
    t.index ["slug"], name: "index_blog_posts_on_slug", unique: true
  end

  create_table "cash_shifts", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Кассовые смены", force: :cascade do |t|
    t.decimal "cash_difference", precision: 10, scale: 2
    t.datetime "closed_at", precision: nil
    t.uuid "closed_by_id"
    t.decimal "closing_cash", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.decimal "expected_cash", precision: 10, scale: 2
    t.text "note"
    t.datetime "opened_at", precision: nil, default: -> { "now()" }, null: false
    t.uuid "opened_by_id", null: false
    t.decimal "opening_cash", precision: 10, scale: 2, default: "0.0", null: false
    t.string "status", default: "open", null: false
    t.uuid "tenant_id", null: false
    t.decimal "total_refunds", precision: 10, scale: 2
    t.decimal "total_sales", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["closed_by_id"], name: "index_cash_shifts_on_closed_by_id"
    t.index ["opened_at"], name: "index_cash_shifts_on_opened_at", order: :desc
    t.index ["opened_by_id"], name: "index_cash_shifts_on_opened_by_id"
    t.index ["status"], name: "index_cash_shifts_on_status"
    t.index ["tenant_id", "status"], name: "idx_one_open_shift_per_tenant", unique: true, where: "((status)::text = 'open'::text)"
    t.index ["tenant_id"], name: "index_cash_shifts_on_tenant_id"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Категории продуктов (Кофе, Чай, Десерты)", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "name", limit: 255, null: false
    t.string "slug", limit: 150, null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_categories_on_created_by_id"
    t.index ["is_active"], name: "index_categories_on_is_active"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
    t.index ["sort_order"], name: "index_categories_on_sort_order"
  end

  create_table "device_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Активные сессии устройств", force: :cascade do |t|
    t.datetime "connected_at", precision: nil, default: -> { "now()" }, null: false
    t.string "connection_id", limit: 255
    t.string "connection_type", limit: 20, null: false
    t.datetime "created_at", null: false
    t.uuid "device_id", null: false
    t.datetime "disconnected_at", precision: nil
    t.jsonb "metadata", default: {}
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["connected_at"], name: "index_device_sessions_on_connected_at"
    t.index ["device_id"], name: "index_device_sessions_on_device_id"
    t.index ["disconnected_at"], name: "index_device_sessions_on_disconnected_at", where: "(disconnected_at IS NULL)"
    t.index ["tenant_id"], name: "index_device_sessions_on_tenant_id"
  end

  create_table "devices", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Зарегистрированные устройства (киоски, планшеты баристы, ТВ)", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_token", limit: 255
    t.string "device_type", limit: 50, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "last_seen_at", precision: nil
    t.jsonb "metadata", default: {}
    t.string "name", limit: 255, null: false
    t.uuid "registered_by_id"
    t.uuid "tenant_id", null: false
    t.datetime "token_expires_at", precision: nil
    t.datetime "updated_at", null: false
    t.index ["device_token"], name: "index_devices_on_device_token", unique: true, where: "(device_token IS NOT NULL)"
    t.index ["device_type"], name: "index_devices_on_device_type"
    t.index ["is_active"], name: "index_devices_on_is_active"
    t.index ["last_seen_at"], name: "index_devices_on_last_seen_at"
    t.index ["registered_by_id"], name: "index_devices_on_registered_by_id"
    t.index ["tenant_id"], name: "index_devices_on_tenant_id"
  end

  create_table "feature_flags", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Флаги для A/B тестов и постепенного раската фич", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "enabled_at", precision: nil
    t.uuid "enabled_by_id"
    t.string "module", limit: 100, null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_feature_flags_on_enabled"
    t.index ["enabled_by_id"], name: "index_feature_flags_on_enabled_by_id"
    t.index ["tenant_id", "module"], name: "index_feature_flags_on_tenant_id_and_module", unique: true
    t.index ["tenant_id"], name: "index_feature_flags_on_tenant_id"
  end

  create_table "fiscal_receipts", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Фискальные чеки (ОФД)", force: :cascade do |t|
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "ofd_provider", limit: 50, null: false
    t.string "ofd_receipt_id", limit: 255
    t.uuid "order_id", null: false
    t.uuid "payment_id", null: false
    t.jsonb "receipt_data", null: false
    t.uuid "refund_id"
    t.datetime "sent_at", precision: nil
    t.string "status", default: "pending", null: false
    t.uuid "tenant_id", null: false
    t.string "type", limit: 20, null: false
    t.datetime "updated_at", null: false
    t.index ["ofd_receipt_id"], name: "index_fiscal_receipts_on_ofd_receipt_id", where: "(ofd_receipt_id IS NOT NULL)"
    t.index ["order_id"], name: "index_fiscal_receipts_on_order_id"
    t.index ["payment_id"], name: "index_fiscal_receipts_on_payment_id"
    t.index ["refund_id"], name: "index_fiscal_receipts_on_refund_id"
    t.index ["status"], name: "index_fiscal_receipts_on_status"
    t.index ["tenant_id"], name: "index_fiscal_receipts_on_tenant_id"
  end

  create_table "ingredient_tenant_stocks", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Остатки ингредиентов по точкам", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "ingredient_id", null: false
    t.datetime "last_updated_at", precision: nil, default: -> { "now()" }, null: false
    t.decimal "min_qty", precision: 10, scale: 3
    t.decimal "qty", precision: 10, scale: 3, default: "0.0", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id", "tenant_id"], name: "idx_its_ingredient_tenant", unique: true
    t.index ["ingredient_id"], name: "index_ingredient_tenant_stocks_on_ingredient_id"
    t.index ["tenant_id", "ingredient_id"], name: "idx_its_zero_qty", where: "(qty = (0)::numeric)"
    t.index ["tenant_id"], name: "index_ingredient_tenant_stocks_on_tenant_id"
    t.check_constraint "qty >= 0::numeric", name: "chk_stock_qty"
  end

  create_table "ingredients", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Глобальный справочник ингредиентов (управляет УК)", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "unit", limit: 10, null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_ingredients_on_is_active"
    t.index ["name"], name: "index_ingredients_on_name"
  end

  create_table "kiosk_carts", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Корзины киоска (привязка к сессии)", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "device_id", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.jsonb "items", default: [], null: false
    t.uuid "session_token", null: false
    t.uuid "tenant_id", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_kiosk_carts_on_device_id"
    t.index ["expires_at"], name: "index_kiosk_carts_on_expires_at"
    t.index ["session_token"], name: "index_kiosk_carts_on_session_token", unique: true
    t.index ["tenant_id"], name: "index_kiosk_carts_on_tenant_id"
  end

  create_table "kiosk_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Сессии пользователей киоска", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "device_id", null: false
    t.string "end_reason", limit: 50
    t.datetime "ended_at", precision: nil
    t.datetime "last_activity_at", precision: nil, default: -> { "now()" }, null: false
    t.jsonb "metadata", default: {}
    t.integer "orders_created", default: 0, null: false
    t.uuid "session_token", null: false
    t.datetime "started_at", precision: nil, default: -> { "now()" }, null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_kiosk_sessions_on_device_id"
    t.index ["ended_at"], name: "index_kiosk_sessions_on_ended_at", where: "(ended_at IS NULL)"
    t.index ["last_activity_at"], name: "index_kiosk_sessions_on_last_activity_at"
    t.index ["session_token"], name: "index_kiosk_sessions_on_session_token", unique: true
    t.index ["tenant_id"], name: "index_kiosk_sessions_on_tenant_id"
  end

  create_table "kiosk_settings", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Настройки киоска точки", force: :cascade do |t|
    t.boolean "allow_card", default: true, null: false
    t.boolean "allow_cash", default: true, null: false
    t.datetime "created_at", null: false
    t.uuid "device_id", null: false
    t.jsonb "display_settings", default: {}
    t.integer "idle_timeout_seconds", default: 300, null: false
    t.boolean "is_active", default: true, null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.text "welcome_text", null: false
    t.index ["device_id"], name: "index_kiosk_settings_on_device_id"
    t.index ["is_active"], name: "index_kiosk_settings_on_is_active"
    t.index ["tenant_id", "device_id"], name: "idx_ks_tenant_device", unique: true
    t.index ["tenant_id"], name: "index_kiosk_settings_on_tenant_id"
  end

  create_table "menu_types", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Типы меню (kiosk, main, seasonal)", force: :cascade do |t|
    t.string "code", limit: 50, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_menu_types_on_code", unique: true
  end

  create_table "mobile_customers", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Клиенты мобильного приложения", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", limit: 255
    t.string "first_name", limit: 100
    t.boolean "is_active", default: true, null: false
    t.datetime "last_login_at", precision: nil
    t.string "last_name", limit: 100
    t.string "phone", limit: 20, null: false
    t.boolean "push_enabled", default: false, null: false
    t.string "push_token", limit: 255
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_mobile_customers_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["is_active"], name: "index_mobile_customers_on_is_active"
    t.index ["phone"], name: "index_mobile_customers_on_phone", unique: true
  end

  create_table "mobile_otp_codes", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "OTP коды для авторизации в мобильном приложении", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.string "code", limit: 6, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.boolean "is_used", default: false, null: false
    t.string "phone", limit: 20, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_mobile_otp_codes_on_code"
    t.index ["expires_at"], name: "index_mobile_otp_codes_on_expires_at"
    t.index ["is_used"], name: "index_mobile_otp_codes_on_is_used"
    t.index ["phone"], name: "index_mobile_otp_codes_on_phone"
  end

  create_table "mobile_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Сессии мобильного приложения", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "customer_id", null: false
    t.string "device_id", limit: 255
    t.string "device_type", limit: 50
    t.datetime "expires_at", precision: nil, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "last_used_at", precision: nil
    t.jsonb "metadata", default: {}
    t.string "refresh_token", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_mobile_sessions_on_customer_id"
    t.index ["expires_at"], name: "index_mobile_sessions_on_expires_at"
    t.index ["is_active"], name: "index_mobile_sessions_on_is_active"
    t.index ["refresh_token"], name: "index_mobile_sessions_on_refresh_token", unique: true
  end

  create_table "modifier_option_recipes", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Как модификаторы влияют на рецептуру", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "ingredient_id", null: false
    t.uuid "option_id", null: false
    t.decimal "qty_change", precision: 10, scale: 3, null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_modifier_option_recipes_on_ingredient_id"
    t.index ["option_id", "ingredient_id"], name: "idx_mor_option_ingredient", unique: true
    t.index ["option_id"], name: "index_modifier_option_recipes_on_option_id"
  end

  create_table "modifier_option_tenant_settings", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Локальные наценки на модификаторы по точкам", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "option_id", null: false
    t.decimal "price_delta_override", precision: 10, scale: 2, null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "updated_by_id"
    t.index ["option_id"], name: "index_modifier_option_tenant_settings_on_option_id"
    t.index ["tenant_id", "option_id"], name: "idx_mots_tenant_option", unique: true
    t.index ["tenant_id"], name: "index_modifier_option_tenant_settings_on_tenant_id"
    t.index ["updated_by_id"], name: "index_modifier_option_tenant_settings_on_updated_by_id"
  end

  create_table "order_cancel_reasons", primary_key: "code", id: { type: :string, limit: 50 }, comment: "Справочник причин отмены заказа", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "name", limit: 100, null: false
    t.integer "sort_order", default: 0
    t.datetime "updated_at", null: false
  end

  create_table "order_items", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Позиции заказа (продукты + модификаторы)", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "modifier_options", default: {}, comment: "JSON: {\"milk_type\": \"uuid\", \"syrup\": \"uuid\"}"
    t.uuid "order_id", null: false
    t.uuid "product_id", null: false
    t.string "product_name", limit: 255, null: false, comment: "Снапшот названия на момент заказа"
    t.integer "quantity", default: 1, null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["modifier_options"], name: "index_order_items_on_modifier_options", using: :gin
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.check_constraint "quantity > 0", name: "chk_order_item_quantity"
    t.check_constraint "unit_price > 0::numeric AND total_price = (unit_price * quantity::numeric)", name: "chk_order_item_prices"
  end

  create_table "order_status_logs", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "История изменений статуса заказа", force: :cascade do |t|
    t.uuid "changed_by_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.uuid "device_id"
    t.uuid "order_id", null: false
    t.string "source", limit: 50, default: "barista"
    t.enum "status_from", enum_type: "order_status"
    t.enum "status_to", null: false, enum_type: "order_status"
    t.datetime "updated_at", null: false
    t.index ["changed_by_id"], name: "index_order_status_logs_on_changed_by_id"
    t.index ["created_at"], name: "index_order_status_logs_on_created_at"
    t.index ["device_id"], name: "index_order_status_logs_on_device_id"
    t.index ["order_id"], name: "index_order_status_logs_on_order_id"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Заказы клиентов", force: :cascade do |t|
    t.text "cancel_reason"
    t.string "cancel_reason_code", limit: 50
    t.string "cancel_stage", limit: 50
    t.uuid "cash_shift_id"
    t.datetime "created_at", null: false
    t.uuid "customer_id"
    t.string "customer_name", limit: 255
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "final_amount", precision: 10, scale: 2, null: false
    t.string "locker_cell", limit: 10
    t.string "order_number", limit: 20, null: false, comment: "Читаемый номер заказа #YYYYMM-#### (уникален в пределах тенанта)"
    t.bigserial "order_sequence", null: false, comment: "Автоинкремент для генерации номера заказа"
    t.uuid "promo_code_id"
    t.datetime "qr_expires_at", precision: nil
    t.uuid "qr_token"
    t.enum "source", null: false, enum_type: "order_source"
    t.enum "status", default: "pending_payment", null: false, enum_type: "order_status"
    t.uuid "tenant_id", null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["cash_shift_id"], name: "index_orders_on_cash_shift_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["order_number"], name: "index_orders_on_order_number"
    t.index ["qr_token"], name: "index_orders_on_qr_token", where: "(qr_token IS NOT NULL)"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["tenant_id", "created_at"], name: "index_orders_on_tenant_id_and_created_at", order: { created_at: :desc }
    t.index ["tenant_id", "order_number"], name: "idx_orders_tenant_number", unique: true
    t.index ["tenant_id", "status"], name: "index_orders_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_orders_on_tenant_id"
    t.check_constraint "total_amount > 0::numeric AND discount_amount >= 0::numeric AND final_amount >= 0::numeric AND final_amount = (total_amount - discount_amount)", name: "chk_order_amounts"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "payment_polling_attempts", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Попытки опроса статуса платежа у провайдера", force: :cascade do |t|
    t.integer "attempt_number", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.uuid "payment_id", null: false
    t.jsonb "provider_response"
    t.enum "status", enum_type: "payment_status"
    t.boolean "success", default: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_payment_polling_attempts_on_created_at"
    t.index ["payment_id"], name: "index_payment_polling_attempts_on_payment_id"
  end

  create_table "payment_status_logs", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "История статусов платежей", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "note"
    t.uuid "payment_id", null: false
    t.jsonb "provider_response", default: {}
    t.string "source", limit: 50, null: false
    t.enum "status_from", enum_type: "payment_status"
    t.enum "status_to", null: false, enum_type: "payment_status"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_payment_status_logs_on_created_at"
    t.index ["payment_id"], name: "index_payment_status_logs_on_payment_id"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Платежи по заказам", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.enum "method", null: false, enum_type: "payment_method"
    t.uuid "order_id", null: false
    t.datetime "paid_at", precision: nil
    t.string "provider", limit: 50, null: false
    t.jsonb "provider_data", default: {}
    t.string "provider_payment_id", limit: 255
    t.enum "status", default: "pending", null: false, enum_type: "payment_status"
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["provider_payment_id"], name: "index_payments_on_provider_payment_id", where: "(provider_payment_id IS NOT NULL)"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["tenant_id", "status"], name: "index_payments_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_payments_on_tenant_id"
  end

  create_table "product_menu_visibilities", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Видимость продуктов в разных меню", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_visible", default: true, null: false
    t.uuid "menu_type_id", null: false
    t.uuid "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_type_id"], name: "index_product_menu_visibilities_on_menu_type_id"
    t.index ["product_id", "menu_type_id"], name: "idx_pmv_product_menu", unique: true
    t.index ["product_id"], name: "index_product_menu_visibilities_on_product_id"
  end

  create_table "product_modifier_groups", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Группы модификаторов (Размер, Молоко, Сироп)", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_required", default: false, null: false
    t.string "name", limit: 100, null: false
    t.uuid "product_id", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_modifier_groups_on_product_id"
    t.index ["sort_order"], name: "index_product_modifier_groups_on_sort_order"
  end

  create_table "product_modifier_options", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Опции модификаторов (S/M/L, Обычное/Овсяное)", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "group_id", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", limit: 100, null: false
    t.decimal "price_delta", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_product_modifier_options_on_group_id"
    t.index ["is_active"], name: "index_product_modifier_options_on_is_active"
    t.index ["sort_order"], name: "index_product_modifier_options_on_sort_order"
  end

  create_table "product_price_histories", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "История изменения цен продуктов по точкам", force: :cascade do |t|
    t.uuid "changed_by_id"
    t.datetime "created_at", null: false
    t.decimal "price_new", precision: 10, scale: 2, null: false
    t.decimal "price_old", precision: 10, scale: 2
    t.uuid "product_id", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["changed_by_id"], name: "index_product_price_histories_on_changed_by_id"
    t.index ["created_at"], name: "index_product_price_histories_on_created_at", order: :desc
    t.index ["product_id"], name: "index_product_price_histories_on_product_id"
    t.index ["tenant_id"], name: "index_product_price_histories_on_tenant_id"
  end

  create_table "product_recipes", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Рецептуры продуктов (сколько ингредиентов на 1 порцию)", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "ingredient_id", null: false
    t.uuid "product_id", null: false
    t.decimal "qty_per_serving", precision: 10, scale: 3, null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_product_recipes_on_ingredient_id"
    t.index ["product_id", "ingredient_id"], name: "idx_recipes_product_ingredient", unique: true
    t.index ["product_id"], name: "index_product_recipes_on_product_id"
    t.check_constraint "qty_per_serving > 0::numeric", name: "chk_recipe_qty"
  end

  create_table "product_tenant_settings", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Настройки продукта для конкретной точки", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_enabled", default: true, null: false
    t.boolean "is_sold_out", default: false, null: false
    t.decimal "price", precision: 10, scale: 2
    t.uuid "price_updated_by_id"
    t.uuid "product_id", null: false
    t.string "sold_out_reason", limit: 50, comment: "manual или stock_empty (автостоп)"
    t.decimal "stock_qty", precision: 10, scale: 3
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["price_updated_by_id"], name: "index_product_tenant_settings_on_price_updated_by_id"
    t.index ["product_id", "tenant_id"], name: "idx_pts_product_tenant", unique: true
    t.index ["product_id"], name: "index_product_tenant_settings_on_product_id"
    t.index ["tenant_id", "is_enabled", "is_sold_out"], name: "idx_pts_tenant_enabled"
    t.index ["tenant_id"], name: "index_product_tenant_settings_on_tenant_id"
    t.check_constraint "is_sold_out = false AND sold_out_reason IS NULL OR is_sold_out = true AND (sold_out_reason::text = ANY (ARRAY['manual'::character varying, 'stock_empty'::character varying]::text[]))", name: "chk_sold_out_reason"
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Глобальный каталог продуктов (управляет УК)", force: :cascade do |t|
    t.decimal "base_price", precision: 10, scale: 2, comment: "Базовая цена (рекомендованная), точки могут переопределять"
    t.uuid "category_id", null: false
    t.uuid "copied_from_id"
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.text "description"
    t.string "image_url", limit: 500
    t.boolean "is_active", default: true, null: false
    t.string "name", limit: 255, null: false
    t.string "slug", limit: 150, null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["copied_from_id"], name: "index_products_on_copied_from_id"
    t.index ["created_by_id"], name: "index_products_on_created_by_id"
    t.index ["is_active"], name: "index_products_on_is_active"
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.index ["sort_order"], name: "index_products_on_sort_order"
  end

  create_table "refunds", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Возвраты средств", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.uuid "initiated_by_id"
    t.uuid "order_id", null: false
    t.uuid "payment_id", null: false
    t.jsonb "provider_data", default: {}
    t.string "provider_refund_id", limit: 255
    t.text "reason", null: false
    t.string "status", default: "pending", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["initiated_by_id"], name: "index_refunds_on_initiated_by_id"
    t.index ["order_id"], name: "index_refunds_on_order_id"
    t.index ["payment_id"], name: "index_refunds_on_payment_id"
    t.index ["provider_refund_id"], name: "index_refunds_on_provider_refund_id", where: "(provider_refund_id IS NOT NULL)"
    t.index ["status"], name: "index_refunds_on_status"
    t.index ["tenant_id"], name: "index_refunds_on_tenant_id"
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Роли пользователей", force: :cascade do |t|
    t.string "code", limit: 50, null: false, comment: "Уникальный код роли для проверок в коде"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_system", default: false, null: false, comment: "Системная роль, нельзя удалить"
    t.string "name", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_roles_on_code", unique: true
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Активные сессии пользователей", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.string "ip_address", limit: 45
    t.datetime "revoked_at", precision: nil
    t.uuid "tenant_id"
    t.string "token", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.string "user_agent", limit: 500
    t.uuid "user_id", null: false
    t.index ["expires_at"], name: "index_sessions_on_expires_at"
    t.index ["tenant_id"], name: "index_sessions_on_tenant_id"
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shift_cash_operations", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Кассовые операции в смене (внесение/изъятие наличных)", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.text "note"
    t.string "operation_type", limit: 50, null: false
    t.uuid "shift_id", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_shift_cash_operations_on_created_at", order: :desc
    t.index ["created_by_id"], name: "index_shift_cash_operations_on_created_by_id"
    t.index ["operation_type"], name: "index_shift_cash_operations_on_operation_type"
    t.index ["shift_id"], name: "index_shift_cash_operations_on_shift_id"
    t.index ["tenant_id"], name: "index_shift_cash_operations_on_tenant_id"
  end

  create_table "shift_staffs", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Персонал в смене", force: :cascade do |t|
    t.datetime "checked_in_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "checked_out_at", precision: nil
    t.datetime "created_at", null: false
    t.string "role_in_shift", limit: 50, null: false
    t.uuid "shift_id", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["checked_out_at"], name: "index_shift_staffs_on_checked_out_at", where: "(checked_out_at IS NULL)"
    t.index ["shift_id", "user_id"], name: "idx_shift_staffs_unique", unique: true
    t.index ["shift_id"], name: "index_shift_staffs_on_shift_id"
    t.index ["tenant_id"], name: "index_shift_staffs_on_tenant_id"
    t.index ["user_id"], name: "index_shift_staffs_on_user_id"
  end

  create_table "shifts", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Смены (расширенная версия cash_shifts)", force: :cascade do |t|
    t.decimal "cash_difference", precision: 10, scale: 2
    t.datetime "closed_at", precision: nil
    t.uuid "closed_by_id"
    t.decimal "closing_cash", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.decimal "expected_cash", precision: 10, scale: 2
    t.text "note"
    t.datetime "opened_at", precision: nil, default: -> { "now()" }, null: false
    t.uuid "opened_by_id", null: false
    t.decimal "opening_cash", precision: 10, scale: 2, default: "0.0", null: false
    t.enum "status", default: "open", null: false, enum_type: "shift_status"
    t.uuid "tenant_id", null: false
    t.decimal "total_refunds", precision: 10, scale: 2
    t.decimal "total_sales", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["closed_by_id"], name: "index_shifts_on_closed_by_id"
    t.index ["opened_at"], name: "index_shifts_on_opened_at", order: :desc
    t.index ["opened_by_id"], name: "index_shifts_on_opened_by_id"
    t.index ["status"], name: "index_shifts_on_status"
    t.index ["tenant_id"], name: "index_shifts_on_tenant_id"
  end

  create_table "stock_movement_items", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Позиции движения (какие ингредиенты, сколько)", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "ingredient_id", null: false
    t.uuid "movement_id", null: false
    t.decimal "qty_change", precision: 10, scale: 3, null: false
    t.decimal "unit_cost", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_stock_movement_items_on_ingredient_id"
    t.index ["movement_id"], name: "index_stock_movement_items_on_movement_id"
  end

  create_table "stock_movements", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Движения склада (приход, расход, инвентаризация)", force: :cascade do |t|
    t.datetime "confirmed_at", precision: nil
    t.uuid "confirmed_by_id"
    t.datetime "created_at", null: false
    t.uuid "created_by_id"
    t.string "movement_type", limit: 50, null: false
    t.text "note"
    t.uuid "reference_id"
    t.string "status", default: "draft", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmed_by_id"], name: "index_stock_movements_on_confirmed_by_id"
    t.index ["created_by_id"], name: "index_stock_movements_on_created_by_id"
    t.index ["movement_type"], name: "index_stock_movements_on_movement_type"
    t.index ["reference_id"], name: "index_stock_movements_on_reference_id", where: "(reference_id IS NOT NULL)"
    t.index ["status"], name: "index_stock_movements_on_status"
    t.index ["tenant_id"], name: "index_stock_movements_on_tenant_id"
  end

  create_table "tenants", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Точки продаж (кофейни)", force: :cascade do |t|
    t.text "address"
    t.string "city", limit: 100
    t.string "country", limit: 2, default: "RU", null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "RUB", null: false
    t.string "name", null: false
    t.uuid "organization_id"
    t.jsonb "settings", default: {}, comment: "Настройки точки: график работы, контакты, etc"
    t.string "slug", null: false, comment: "URL-friendly идентификатор точки"
    t.string "status", default: "active", null: false
    t.string "timezone", limit: 50, default: "Europe/Moscow"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["country"], name: "index_tenants_on_country"
    t.index ["organization_id"], name: "index_tenants_on_organization_id"
    t.index ["slug"], name: "index_tenants_on_slug", unique: true
    t.index ["status"], name: "index_tenants_on_status"
    t.index ["type"], name: "index_tenants_on_type"
  end

  create_table "tv_board_settings", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Настройки ТВ-борда для точки", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "custom_css", default: {}
    t.integer "display_seconds_ready", default: 60, null: false
    t.integer "show_order_count", default: 10, null: false
    t.uuid "tenant_id", null: false
    t.string "theme", limit: 20, default: "dark", null: false
    t.datetime "updated_at", null: false
    t.uuid "updated_by_id"
    t.index ["tenant_id"], name: "index_tv_board_settings_on_tenant_id"
    t.index ["updated_by_id"], name: "index_tv_board_settings_on_updated_by_id"
  end

  create_table "user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Связь пользователей и ролей (many-to-many)", force: :cascade do |t|
    t.datetime "granted_at", precision: nil, default: -> { "now()" }
    t.uuid "granted_by_id"
    t.uuid "role_id", null: false
    t.uuid "tenant_id"
    t.uuid "user_id", null: false
    t.index ["granted_by_id"], name: "index_user_roles_on_granted_by_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["tenant_id"], name: "index_user_roles_on_tenant_id"
    t.index ["user_id", "role_id", "tenant_id"], name: "idx_user_roles_unique", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, comment: "Пользователи системы (сотрудники кофеен)", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "last_login_at", precision: nil
    t.string "name", null: false
    t.uuid "organization_id"
    t.string "password_hash", null: false
    t.string "phone", limit: 20
    t.string "status", default: "active", null: false
    t.uuid "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["phone"], name: "index_users_on_phone", unique: true, where: "(phone IS NOT NULL)"
    t.index ["status"], name: "index_users_on_status"
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  add_foreign_key "blog_posts", "blog_categories"
  add_foreign_key "cash_shifts", "tenants", on_delete: :cascade
  add_foreign_key "cash_shifts", "users", column: "closed_by_id", on_delete: :nullify
  add_foreign_key "cash_shifts", "users", column: "opened_by_id", on_delete: :restrict
  add_foreign_key "categories", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "device_sessions", "devices", on_delete: :cascade
  add_foreign_key "device_sessions", "tenants", on_delete: :cascade
  add_foreign_key "devices", "tenants", on_delete: :cascade
  add_foreign_key "devices", "users", column: "registered_by_id", on_delete: :nullify
  add_foreign_key "feature_flags", "tenants", on_delete: :cascade
  add_foreign_key "feature_flags", "users", column: "enabled_by_id", on_delete: :nullify
  add_foreign_key "fiscal_receipts", "orders", on_delete: :cascade
  add_foreign_key "fiscal_receipts", "payments", on_delete: :cascade
  add_foreign_key "fiscal_receipts", "refunds", on_delete: :cascade
  add_foreign_key "fiscal_receipts", "tenants", on_delete: :cascade
  add_foreign_key "ingredient_tenant_stocks", "ingredients", on_delete: :cascade
  add_foreign_key "ingredient_tenant_stocks", "tenants", on_delete: :cascade
  add_foreign_key "kiosk_carts", "devices", on_delete: :cascade
  add_foreign_key "kiosk_carts", "tenants", on_delete: :cascade
  add_foreign_key "kiosk_sessions", "devices", on_delete: :cascade
  add_foreign_key "kiosk_sessions", "tenants", on_delete: :cascade
  add_foreign_key "kiosk_settings", "devices", on_delete: :cascade
  add_foreign_key "kiosk_settings", "tenants", on_delete: :cascade
  add_foreign_key "mobile_sessions", "mobile_customers", column: "customer_id", on_delete: :cascade
  add_foreign_key "modifier_option_recipes", "ingredients", on_delete: :cascade
  add_foreign_key "modifier_option_recipes", "product_modifier_options", column: "option_id", on_delete: :cascade
  add_foreign_key "modifier_option_tenant_settings", "product_modifier_options", column: "option_id", on_delete: :cascade
  add_foreign_key "modifier_option_tenant_settings", "tenants", on_delete: :cascade
  add_foreign_key "modifier_option_tenant_settings", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "order_items", "orders", on_delete: :cascade
  add_foreign_key "order_items", "products", name: "fk_order_items_product", on_delete: :restrict
  add_foreign_key "order_status_logs", "devices", name: "fk_order_status_logs_device", on_delete: :nullify
  add_foreign_key "order_status_logs", "orders", on_delete: :cascade
  add_foreign_key "order_status_logs", "users", column: "changed_by_id", on_delete: :nullify
  add_foreign_key "orders", "mobile_customers", column: "customer_id", name: "fk_orders_customer", on_delete: :nullify
  add_foreign_key "orders", "order_cancel_reasons", column: "cancel_reason_code", primary_key: "code", on_delete: :nullify
  add_foreign_key "orders", "tenants", on_delete: :cascade
  add_foreign_key "payment_polling_attempts", "payments", on_delete: :cascade
  add_foreign_key "payment_status_logs", "payments", on_delete: :cascade
  add_foreign_key "payments", "orders", on_delete: :cascade
  add_foreign_key "payments", "tenants", on_delete: :cascade
  add_foreign_key "product_menu_visibilities", "menu_types", on_delete: :cascade
  add_foreign_key "product_menu_visibilities", "products", on_delete: :cascade
  add_foreign_key "product_modifier_groups", "products", on_delete: :cascade
  add_foreign_key "product_modifier_options", "product_modifier_groups", column: "group_id", on_delete: :cascade
  add_foreign_key "product_price_histories", "products", on_delete: :cascade
  add_foreign_key "product_price_histories", "tenants", on_delete: :cascade
  add_foreign_key "product_price_histories", "users", column: "changed_by_id", on_delete: :nullify
  add_foreign_key "product_recipes", "ingredients", on_delete: :cascade
  add_foreign_key "product_recipes", "products", on_delete: :cascade
  add_foreign_key "product_tenant_settings", "products", on_delete: :cascade
  add_foreign_key "product_tenant_settings", "tenants", on_delete: :cascade
  add_foreign_key "product_tenant_settings", "users", column: "price_updated_by_id", on_delete: :nullify
  add_foreign_key "products", "categories", on_delete: :restrict
  add_foreign_key "products", "products", column: "copied_from_id", on_delete: :nullify
  add_foreign_key "products", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "refunds", "orders", on_delete: :cascade
  add_foreign_key "refunds", "payments", on_delete: :cascade
  add_foreign_key "refunds", "tenants", on_delete: :cascade
  add_foreign_key "refunds", "users", column: "initiated_by_id", on_delete: :nullify
  add_foreign_key "sessions", "tenants", on_delete: :cascade
  add_foreign_key "sessions", "users", on_delete: :cascade
  add_foreign_key "shift_cash_operations", "shifts", on_delete: :cascade
  add_foreign_key "shift_cash_operations", "tenants", on_delete: :cascade
  add_foreign_key "shift_cash_operations", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "shift_staffs", "shifts", on_delete: :cascade
  add_foreign_key "shift_staffs", "tenants", on_delete: :cascade
  add_foreign_key "shift_staffs", "users", on_delete: :restrict
  add_foreign_key "shifts", "tenants", on_delete: :cascade
  add_foreign_key "shifts", "users", column: "closed_by_id", on_delete: :nullify
  add_foreign_key "shifts", "users", column: "opened_by_id", on_delete: :restrict
  add_foreign_key "stock_movement_items", "ingredients", on_delete: :restrict
  add_foreign_key "stock_movement_items", "stock_movements", column: "movement_id", on_delete: :cascade
  add_foreign_key "stock_movements", "tenants", on_delete: :cascade
  add_foreign_key "stock_movements", "users", column: "confirmed_by_id", on_delete: :nullify
  add_foreign_key "stock_movements", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "tenants", "organizations"
  add_foreign_key "tv_board_settings", "tenants", on_delete: :cascade
  add_foreign_key "tv_board_settings", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "user_roles", "roles", on_delete: :cascade
  add_foreign_key "user_roles", "tenants", on_delete: :cascade
  add_foreign_key "user_roles", "users", column: "granted_by_id", on_delete: :nullify
  add_foreign_key "user_roles", "users", on_delete: :cascade
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "tenants", on_delete: :nullify
end
