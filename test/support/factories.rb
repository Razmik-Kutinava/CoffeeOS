module TestFactories
  def disable_rls_once!
    return if defined?(@@rls_disabled) && @@rls_disabled

    conn = ActiveRecord::Base.connection
    tables = conn.select_values("SELECT relname FROM pg_class WHERE relrowsecurity = true AND relkind = 'r'")
    tables.each do |t|
      conn.execute("ALTER TABLE #{conn.quote_table_name(t)} DISABLE ROW LEVEL SECURITY")
    end

    @@rls_disabled = true
  end

  def create_organization!(name: "Организация", slug: nil)
    disable_rls_once!
    slug ||= "org-#{SecureRandom.hex(4)}"
    Organization.create!(name: name, slug: slug)
  end

  def create_tenant!(name: "Точка", slug: nil, organization: nil)
    disable_rls_once!
    slug ||= "tenant-#{SecureRandom.hex(4)}"
    Tenant.create!(
      organization: organization,
      name: name,
      slug: slug,
      type: "sales_point",
      status: "active",
      currency: "RUB",
      country: "RU",
      timezone: "Europe/Moscow"
    )
  end

  def create_role!(code:, name: nil)
    Role.find_or_create_by!(code: code) { |r| r.name = name || code.humanize }
  end

  def create_user!(tenant:, role_codes:, email: nil, phone: nil, name: "User", password: "pass123", organization: nil)
    email ||= "user-#{SecureRandom.hex(4)}@test.local"
    user = User.create!(
      tenant: tenant,
      organization: organization,
      name: name,
      email: email,
      phone: phone,
      status: "active",
      password: password
    )

    role_codes.each do |code|
      role = create_role!(code: code, name: code.humanize)
      UserRole.create!(user: user, role: role, tenant: tenant)
    end

    user
  end

  def create_uk_admin!(email: "uk@test.local", password: "pass123")
    disable_rls_once!
    t = create_tenant!(name: "UK anchor", slug: "uk-anchor-#{SecureRandom.hex(4)}")
    create_user!(tenant: t, role_codes: %w[ук_global_admin], email: email, password: password, name: "UK")
  end

  def create_category!(name: "Категория", slug: nil)
    slug ||= "cat-#{SecureRandom.hex(4)}"
    Category.create!(name: name, slug: slug, is_active: true, sort_order: 1)
  end

  def create_product!(category:, name: "Продукт", slug: nil)
    slug ||= "prod-#{SecureRandom.hex(4)}"
    Product.create!(name: name, slug: slug, category: category, sort_order: 1)
  end

  def enable_product_for_tenant!(tenant:, product:, price: 100, is_sold_out: false, is_enabled: true)
    ProductTenantSetting.create!(
      tenant: tenant,
      product: product,
      price: price,
      is_enabled: is_enabled,
      is_sold_out: is_sold_out
    )
  end

  def open_cash_shift!(tenant:, opened_by:)
    CashShift.create!(
      tenant: tenant,
      status: "open",
      opened_by: opened_by,
      opened_at: Time.current,
      opening_cash: 0
    )
  end

  def create_mobile_customer!(phone: "+79#{format('%09d', rand(1_000_000_000))}")
    MobileCustomer.create!(
      phone: phone,
      first_name: "Test",
      last_name: "Customer",
      is_active: true
    )
  end

  def login_as!(user, password: "pass123", tenant_id: nil)
    rack_attack_enabled = Rack::Attack.enabled if defined?(Rack::Attack)
    Rack::Attack.enabled = false if defined?(Rack::Attack)

    post "/login", params: { email: user.email, password: password, tenant_id: tenant_id }
    assert_response :redirect, "ожидался редирект после логина"
    follow_redirect!
    follow_redirect! if response.redirect?
  ensure
    Rack::Attack.enabled = rack_attack_enabled if defined?(Rack::Attack) && !rack_attack_enabled.nil?
  end
end

