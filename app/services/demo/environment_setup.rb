# frozen_string_literal: true

module Demo
  # Идемпотентная демо-среда В1: 1 org, 2 точки продаж, заготовочный цех, каталог, PTS, пользователи с ролями.
  # Вызывать: Demo::EnvironmentSetup.call или bin/rails demo:seed
  class EnvironmentSetup
    DEMO_PASSWORD = "demo123456"

    ORG_SLUG = "demo-coffeeos"
    ORG_NAME = "Demo CoffeeOS"
    ORG_ALT_SLUG = "demo-coffeeos-alt"
    ORG_ALT_NAME = "Demo CoffeeOS Alt"

    TENANT_A_SLUG = "demo-point-a"
    TENANT_A_NAME = "Demo Coffee Point A"
    TENANT_B_SLUG = "demo-point-b"
    TENANT_B_NAME = "Demo Coffee Point B"
    TENANT_C_SLUG = "demo-point-c"
    TENANT_C_NAME = "Demo Coffee Point C"
    TENANT_KITCHEN_SLUG = "demo-prep-kitchen"
    TENANT_KITCHEN_NAME = "Demo Prep Kitchen"

    # B1.14-3b: город + координаты для дропдауна «ближайшие в городе».
    DEMO_TENANT_LOCATIONS = {
      TENANT_A_SLUG => {
        city: "Москва", address: "ул. Ленина, 10",
        latitude: 55.7558, longitude: 37.6173
      },
      TENANT_B_SLUG => {
        city: "Москва", address: "ул. Пушкина, 5",
        latitude: 55.7619, longitude: 37.6056
      },
      TENANT_C_SLUG => {
        city: "Москва", address: "ул. Тверская, 12",
        latitude: 55.7568, longitude: 37.6158
      },
      TENANT_KITCHEN_SLUG => {
        city: "Москва", address: "пр-д Заготовочный, 1",
        latitude: 55.7500, longitude: 37.6200
      }
    }.freeze

    ROLES = [
      { code: "barista", name: "Бариста" },
      { code: "shift_manager", name: "Сменный менеджер" },
      { code: "general_manager", name: "General Manager" },
      { code: "franchise_manager", name: "Менеджер франшизы" },
      { code: "prep_kitchen_manager", name: "Менеджер заготовочного цеха" },
      { code: "prep_kitchen_worker", name: "Работник заготовочного цеха" },
      { code: "ук_global_admin", name: "УК — глобальный админ" }
    ].freeze

    USERS = [
      { email: "uk@demo.coffeeos.local", name: "УК Demo", roles: %w[ук_global_admin], tenant: :a },
      { email: "franchise@demo.coffeeos.local", name: "Франчайзи Demo", roles: %w[franchise_manager], tenant: :a, organization: true },
      { email: "barista-a@demo.coffeeos.local", name: "Бариста A", roles: %w[barista], tenant: :a },
      { email: "barista-b@demo.coffeeos.local", name: "Бариста B", roles: %w[barista], tenant: :b },
      { email: "gm-a@demo.coffeeos.local", name: "GM Point A", roles: %w[general_manager], tenant: :a },
      { email: "gm-b@demo.coffeeos.local", name: "GM Point B", roles: %w[general_manager], tenant: :b },
      { email: "shift-a@demo.coffeeos.local", name: "Shift Manager A", roles: %w[shift_manager], tenant: :a },
      { email: "pk-manager@demo.coffeeos.local", name: "Менеджер цеха", roles: %w[prep_kitchen_manager], tenant: :kitchen },
      { email: "pk-worker@demo.coffeeos.local", name: "Работник цеха", roles: %w[prep_kitchen_worker], tenant: :kitchen }
    ].freeze

    SALES_POINT_MODULES = {
      "barista" => true,
      "menu" => true,
      "kiosk" => true,
      "prep_kitchen" => false,
      "qr_offers" => true,
      "tv_board" => true
    }.freeze

    KITCHEN_MODULES = {
      "barista" => false,
      "menu" => false,
      "kiosk" => false,
      "prep_kitchen" => true,
      "qr_offers" => false,
      "tv_board" => false
    }.freeze

    ORDER_CANCEL_REASONS = [
      { code: "barista_cancel", name: "Отменено баристой" },
      { code: "customer_changed_mind", name: "Клиент передумал" },
      { code: "other", name: "Другое" }
    ].freeze

    Result = Data.define(
      :organization,
      :organization_alt,
      :tenant_a,
      :tenant_b,
      :tenant_c,
      :tenant_kitchen,
      :products_count,
      :pts_a_count,
      :pts_b_count,
      :pts_c_count,
      :users_count
    )

    def self.call(load_catalog: true)
      new(load_catalog: load_catalog).call
    end

    def initialize(load_catalog: true)
      @load_catalog = load_catalog
    end

    def call
      roles = nil
      org = nil
      tenant_a = nil
      tenant_b = nil
      tenant_c = nil
      tenant_kitchen = nil
      org_alt = nil

      ActiveRecord::Base.transaction do
        roles = ensure_roles!
        org = ensure_organization!
        org_alt = ensure_alt_organization!
        tenant_a = ensure_tenant!(slug: TENANT_A_SLUG, name: TENANT_A_NAME, organization: org, type: "sales_point")
        tenant_b = ensure_tenant!(slug: TENANT_B_SLUG, name: TENANT_B_NAME, organization: org, type: "sales_point")
        tenant_c = ensure_tenant!(slug: TENANT_C_SLUG, name: TENANT_C_NAME, organization: org_alt, type: "sales_point")
        tenant_kitchen = ensure_tenant!(
          slug: TENANT_KITCHEN_SLUG,
          name: TENANT_KITCHEN_NAME,
          organization: org,
          type: "production_kitchen"
        )
        ensure_module_flags!(tenant_a, SALES_POINT_MODULES)
        ensure_module_flags!(tenant_b, SALES_POINT_MODULES)
        ensure_module_flags!(tenant_c, SALES_POINT_MODULES)
        ensure_module_flags!(tenant_kitchen, KITCHEN_MODULES)
        load_catalog! if @load_catalog
        repair_brazil_shop_modifier_prices!
        ensure_pts_for_tenants!([ tenant_a, tenant_b, tenant_c ])
        apply_point_price_markup!(tenant_b, markup: 10)
        apply_point_price_markup!(tenant_c, markup: 20)
        ensure_users!(
          organization: org,
          tenant_a: tenant_a,
          tenant_b: tenant_b,
          tenant_kitchen: tenant_kitchen,
          roles: roles
        )
        repair_franchise_organization_links!(organization: org)
        ensure_order_cancel_reasons!
        ensure_prep_kitchen_sales_point_links!(tenant_kitchen: tenant_kitchen, tenant_a: tenant_a, tenant_b: tenant_b)
        ensure_demo_operations!(tenant_a: tenant_a, tenant_b: tenant_b, tenant_kitchen: tenant_kitchen)
        ensure_weekday_schedules!(tenant_a: tenant_a, tenant_b: tenant_b, tenant_c: tenant_c)
      end

      Result.new(
        organization: org,
        organization_alt: org_alt,
        tenant_a: tenant_a,
        tenant_b: tenant_b,
        tenant_c: tenant_c,
        tenant_kitchen: tenant_kitchen,
        products_count: Product.where(is_active: true).count,
        pts_a_count: ProductTenantSetting.where(tenant_id: tenant_a.id).count,
        pts_b_count: ProductTenantSetting.where(tenant_id: tenant_b.id).count,
        pts_c_count: ProductTenantSetting.where(tenant_id: tenant_c.id).count,
        users_count: User.where("email LIKE ?", "%@demo.coffeeos.local").count
      )
    end

    private

    def ensure_roles!
      ROLES.each_with_object({}) do |spec, memo|
        memo[spec[:code]] = Role.find_or_create_by!(code: spec[:code]) do |r|
          r.name = spec[:name]
          r.is_system = true
        end
      end
    end

    def ensure_organization!
      Organization.find_or_create_by!(slug: ORG_SLUG) { |o| o.name = ORG_NAME }
    end

    def ensure_alt_organization!
      Organization.find_or_create_by!(slug: ORG_ALT_SLUG) { |o| o.name = ORG_ALT_NAME }
    end

    def single_point_mode?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_SINGLE_POINT", "false"))
    end

    def tenant_status_for(slug, type)
      return "active" unless single_point_mode?

      return "active" if slug == TENANT_A_SLUG || type == "production_kitchen"

      "inactive"
    end

    def ensure_tenant!(slug:, name:, organization:, type: "sales_point")
      tenant = Tenant.find_or_initialize_by(slug: slug)
      tenant.assign_attributes(
        name: name,
        type: type,
        status: tenant_status_for(slug, type),
        country: "RU",
        currency: "RUB",
        timezone: "Europe/Moscow",
        organization: organization
      )
      tenant.save!
      if (loc = DEMO_TENANT_LOCATIONS[slug])
        tenant.update!(
          city: loc[:city],
          address: loc[:address],
          latitude: loc[:latitude],
          longitude: loc[:longitude]
        )
      end
      tenant
    end

    def load_catalog!
      path = Rails.root.join("db/seeds_shop_catalog.rb")
      return unless path.exist?

      load path
    end

    def ensure_pts_for_tenants!(tenants)
      conn = ActiveRecord::Base.connection
      actor_id = SecureRandom.uuid
      previous_tid = Current.tenant_id

      tenants.each do |tenant|
        conn.execute("SET LOCAL app.current_user_id = #{conn.quote(actor_id)}")
        conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")
        Current.tenant_id = tenant.id
        Platform::TenantOnboarding::CatalogBootstrap.ensure_pts_for_tenant!(tenant, actor_user_id: actor_id)
      end
    ensure
      Current.tenant_id = previous_tid
    end

    # Демо: base_price + markup ₽ (разные цены между точками A/B/C).
    def apply_point_price_markup!(tenant, markup:)
      with_tenant_rls!(tenant) do
        Product.where(is_active: true).find_each do |product|
          bp = product.base_price.presence&.to_d
          next if bp.blank? || bp <= 0

          pts = ProductTenantSetting.find_by(tenant_id: tenant.id, product_id: product.id)
          next unless pts

          target = bp + markup
          pts.update!(price: target) if pts.price.to_d != target
        end
      end
    end

    def ensure_module_flags!(tenant, modules)
      with_tenant_rls!(tenant) { TenantModuleFlags.sync!(tenant, modules) }
    end

    def ensure_users!(organization:, tenant_a:, tenant_b:, tenant_kitchen:, roles:)
      tenants = { a: tenant_a, b: tenant_b, kitchen: tenant_kitchen }

      USERS.each do |spec|
        tenant = tenants.fetch(spec[:tenant])
        upsert_user!(
          email: spec[:email],
          name: spec[:name],
          tenant: tenant,
          organization: spec[:organization] ? organization : nil,
          role_codes: spec[:roles],
          roles: roles
        )
      end
    end

    def upsert_user!(email:, name:, tenant:, organization:, role_codes:, roles:)
      with_tenant_rls!(tenant) do
        user = User.find_or_initialize_by(email: email.downcase.strip)
        user.assign_attributes(
          name: name,
          tenant: tenant,
          organization: organization,
          status: "active",
          password: DEMO_PASSWORD
        )
        user.save!

        conn = ActiveRecord::Base.connection
        conn.execute("SET LOCAL app.current_user_id = #{conn.quote(user.id.to_s)}")

        scope = user.user_roles.where(tenant_id: tenant.id)
        scope.destroy_all

        role_codes.each do |code|
          role = roles.fetch(code)
          role_tenant_id = User::GLOBAL_ROLE_CODES.include?(code) ? nil : tenant.id
          user.user_roles.where(role_id: role.id).where.not(tenant_id: role_tenant_id).destroy_all
          UserRole.find_or_create_by!(user: user, role: role, tenant_id: role_tenant_id)
        end

        user
      end
    end

    # Fly/старые стенды: franchise_manager без organization_id → «Нет организации» при входе.
    def repair_franchise_organization_links!(organization:)
      role = Role.find_by(code: "franchise_manager")
      return unless role

      User.joins(:user_roles).where(user_roles: { role_id: role.id }).distinct.find_each do |user|
        next if user.organization_id.present?

        anchor = organization.tenants.order(:created_at).first
        next unless anchor

        user.update!(organization_id: organization.id, tenant_id: user.tenant_id || anchor.id)
      end
    end

    def ensure_prep_kitchen_sales_point_links!(tenant_kitchen:, tenant_a:, tenant_b:)
      PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: tenant_kitchen, sales_point_tenant: tenant_a)
      PrepKitchen::SalesPointRegistry.link!(prep_kitchen_tenant: tenant_kitchen, sales_point_tenant: tenant_b)
    end

    def ensure_order_cancel_reasons!
      ORDER_CANCEL_REASONS.each_with_index do |spec, index|
        OrderCancelReason.find_or_create_by!(code: spec[:code]) do |reason|
          reason.name = spec[:name]
          reason.sort_order = index
          reason.is_active = true
        end
      end
    end

    def ensure_demo_operations!(tenant_a:, tenant_b:, tenant_kitchen:)
      ensure_demo_shifts_open!(tenant_a, tenant_b)
      ensure_demo_recipes_and_stock!(tenant_a:, tenant_b:)
      ensure_kitchen_stock!(tenant_kitchen)
      reset_demo_pts_availability!([ tenant_a, tenant_b ])
    end

    # Демо: смены A/B открыты — можно проверять оплату и табло без ручного open.
    def ensure_demo_shifts_open!(tenant_a, tenant_b)
      {
        tenant_a => "barista-a@demo.coffeeos.local",
        tenant_b => "barista-b@demo.coffeeos.local"
      }.each do |tenant, email|
        barista = User.find_by!(email: email)
        with_tenant_rls!(tenant) do
          next if CashShift.exists?(tenant_id: tenant.id, status: "open")

          CashShifts::OpenService.call(tenant: tenant, opened_by: barista, opening_cash: 0)
        end
      rescue CashShifts::OpenService::Error
        next
      end
    end

    def ensure_kitchen_stock!(tenant_kitchen)
      ingredient = Ingredient.active.order(:name).first
      return unless ingredient

      conn = ActiveRecord::Base.connection
      ActiveRecord::Base.transaction do
        conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant_kitchen.id.to_s)}")
        IngredientTenantStock.find_or_create_by!(tenant_id: tenant_kitchen.id, ingredient_id: ingredient.id) do |stock|
          stock.qty = 10
          stock.min_qty = 2
        end
      end
    end

    # Block F: техкарты и остатки на точках продаж для E2E списания при заказе.
    def ensure_demo_recipes_and_stock!(tenant_a:, tenant_b:)
      coffee = Ingredient.find_or_create_by!(name: "Demo Coffee Beans") do |ing|
        ing.unit = "g"
        ing.is_active = true
      end
      milk = Ingredient.find_or_create_by!(name: "Demo Milk") do |ing|
        ing.unit = "ml"
        ing.is_active = true
      end

      Product.where(is_active: true).limit(6).find_each do |product|
        ProductRecipe.find_or_create_by!(product: product, ingredient: coffee) do |recipe|
          recipe.qty_per_serving = 18
        end
        ProductRecipe.find_or_create_by!(product: product, ingredient: milk) do |recipe|
          recipe.qty_per_serving = 150
        end
      end

      [ tenant_a, tenant_b ].each do |tenant|
        with_tenant_rls!(tenant) do
          [ coffee, milk ].each do |ingredient|
            IngredientTenantStock.find_or_create_by!(tenant_id: tenant.id, ingredient_id: ingredient.id) do |stock|
              stock.qty = 5_000
              stock.min_qty = 200
            end
          end
        end
      end
    end

    def reset_demo_pts_availability!(tenants)
      tenants.each do |tenant|
        with_tenant_rls!(tenant) do
          ProductTenantSetting.where(tenant_id: tenant.id, is_sold_out: true)
                              .update_all(is_sold_out: false, sold_out_reason: nil, updated_at: Time.current)
        end
      end
    end

    # §2.2 демо: платные модификаторы на витрине (каталог «Черный» / Бразилия).
    def repair_brazil_shop_modifier_prices!
      product = Product.find_by(slug: "filtr-kofe-braziliya")
      return unless product

      [
        [ "Яблочный с корицей%", 15 ],
        [ "Пивной кордиал%", 20 ],
        [ "Мёд%", 40 ]
      ].each do |pattern, price|
        ProductModifierOption.joins(:group)
          .where(product_modifier_groups: { product_id: product.id })
          .where("product_modifier_options.name LIKE ?", pattern)
          .update_all(price_delta: price, updated_at: Time.current)
      end
    end

    # B1.11 + B1.14-3b demo: разное расписание и цены точек A/B/C.
    def ensure_weekday_schedules!(tenant_a:, tenant_b:, tenant_c:)
      sync_tenant_schedule!(tenant_a, {
        0 => { enabled: true, opens_at: "08:00", closes_at: "22:00" },
        1 => { enabled: true, opens_at: "08:00", closes_at: "22:00" },
        2 => { enabled: true, opens_at: "08:00", closes_at: "22:00" },
        3 => { enabled: true, opens_at: "08:00", closes_at: "22:00" },
        4 => { enabled: true, opens_at: "08:00", closes_at: "22:00" },
        5 => { enabled: true, opens_at: "10:00", closes_at: "20:00" },
        6 => { enabled: true, opens_at: "10:00", closes_at: "20:00" }
      })
      sync_tenant_schedule!(tenant_b, {
        0 => { enabled: true, opens_at: "09:00", closes_at: "22:00" },
        1 => { enabled: true, opens_at: "09:00", closes_at: "22:00" },
        2 => { enabled: true, opens_at: "09:00", closes_at: "22:00" },
        3 => { enabled: true, opens_at: "09:00", closes_at: "22:00" },
        4 => { enabled: true, opens_at: "09:00", closes_at: "22:00" },
        5 => { enabled: true, opens_at: "10:00", closes_at: "20:00" },
        6 => { enabled: true, opens_at: "10:00", closes_at: "20:00" }
      })
      sync_tenant_schedule!(tenant_c, {
        0 => { enabled: true, opens_at: "07:00", closes_at: "21:00" },
        1 => { enabled: true, opens_at: "07:00", closes_at: "21:00" },
        2 => { enabled: true, opens_at: "07:00", closes_at: "21:00" },
        3 => { enabled: true, opens_at: "07:00", closes_at: "21:00" },
        4 => { enabled: true, opens_at: "07:00", closes_at: "21:00" },
        5 => { enabled: true, opens_at: "08:00", closes_at: "18:00" },
        6 => { enabled: true, opens_at: "08:00", closes_at: "18:00" }
      })
    end

    def sync_tenant_schedule!(tenant, days)
      with_tenant_rls!(tenant) do
        days.each do |weekday, attrs|
          row = tenant.weekday_schedules.find_or_initialize_by(weekday: weekday)
          row.assign_attributes(attrs)
          row.save!
        end
      end
    end

    def with_tenant_rls!(tenant)
      conn = ActiveRecord::Base.connection
      previous_tid = Current.tenant_id
      ActiveRecord::Base.transaction do
        conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")
        Current.tenant_id = tenant.id
        yield
      end
    ensure
      Current.tenant_id = previous_tid
    end
  end
end
