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

  def create_tenant!(name: "Точка", slug: "tenant-#{SecureRandom.hex(4)}")
    disable_rls_once!
    Tenant.create!(
      name: name,
      slug: slug,
      type: "CoffeeShop",
      status: "active",
      currency: "RUB",
      country: "RU",
      timezone: "Europe/Moscow"
    )
  end

  def create_role!(code:, name: nil)
    Role.find_or_create_by!(code: code) { |r| r.name = name || code.humanize }
  end

  def create_user!(tenant:, role_codes:, email: nil, phone: nil, name: "User", password: "pass123")
    email ||= "user-#{SecureRandom.hex(4)}@test.local"
    user = User.create!(
      tenant: tenant,
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

  def login_as!(user, password: "pass123")
    post "/login", params: { email: user.email, password: password }
    assert_response :redirect
    follow_redirect! rescue nil
  end
end

