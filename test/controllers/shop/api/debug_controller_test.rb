# frozen_string_literal: true

require "test_helper"

class Shop::Api::DebugControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization!(slug: "debug-org")
    @tenant = create_tenant!(name: "Debug Point", slug: "debug-point", organization: @org)
    @other_tenant = create_tenant!(name: "Other Point", slug: "other-point", organization: @org)

    cat = create_category!(name: "Кофе", slug: "kofe-debug")
    @product = create_product!(category: cat, name: "Эспрессо", slug: "espresso-debug")
    @other_product = create_product!(category: cat, name: "Чужой товар", slug: "chuzhoy-debug")

    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 150)
    enable_product_for_tenant!(tenant: @other_tenant, product: @other_product, price: 200)
  end

  # ── Базовый ответ ──────────────────────────────────────────────────────────

  test "GET /shop/api/debug возвращает данные текущего тенанта" do
    get "/shop/api/debug", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    data = response.parsed_body
    assert_equal @tenant.id, data.dig("resolved_tenant", "id")
  end

  test "ответ содержит products_for_tenant и product_tenant_settings" do
    get "/shop/api/debug", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    data = response.parsed_body
    assert data.key?("products_for_tenant"), "должен быть ключ products_for_tenant"
    assert data.key?("product_tenant_settings"), "должен быть ключ product_tenant_settings"
    assert data.key?("categories_for_tenant"), "должен быть ключ categories_for_tenant"
  end

  # ── Tenant isolation ───────────────────────────────────────────────────────

  test "возвращает только товары своего тенанта, не чужие" do
    get "/shop/api/debug", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    data = response.parsed_body

    product_ids = data["products_for_tenant"].map { |p| p["id"] }
    assert_includes product_ids, @product.id, "должен содержать товар тенанта"
    assert_not_includes product_ids, @other_product.id, "НЕ должен содержать товар чужого тенанта"
  end

  test "PTS возвращаются только для текущего тенанта" do
    get "/shop/api/debug", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    data = response.parsed_body

    pts_product_ids = data["product_tenant_settings"].map { |pts| pts["product_id"] }
    assert_includes pts_product_ids, @product.id
    assert_not_includes pts_product_ids, @other_product.id
  end

  test "ответ не содержит данных других тенантов (нет ключа tenants со списком всех)" do
    get "/shop/api/debug", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    data = response.parsed_body

    assert_not data.key?("tenants"), "не должно быть списка всех тенантов"
    assert_not data.key?("all_products"), "не должно быть всех продуктов без фильтра"
  end

  test "ответ не содержит ENV переменных" do
    get "/shop/api/debug", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    data = response.parsed_body

    assert_not data.key?("env"), "ENV переменные не должны утекать в ответ"
  end

  # ── Tenant resolution ──────────────────────────────────────────────────────

  test "без заголовка X-Shop-Tenant резолвится через fallback на первый активный тенант" do
    # resolved_shop_tenant_id всегда находит первый активный тенант как fallback —
    # 422 возникает только при полностью пустой БД (нет ни одного активного тенанта)
    get "/shop/api/debug"
    assert_response :success
    data = response.parsed_body
    assert data.dig("resolved_tenant", "id").present?, "fallback должен вернуть тенант"
  end

  test "с несуществующим tenant_id возвращает 404" do
    get "/shop/api/debug", headers: { "X-Shop-Tenant" => "00000000-0000-0000-0000-000000000000" }
    assert_response :not_found
  end

  test "с неактивным тенантом (нет данных) — ответ ОК, пустой список" do
    empty_tenant = create_tenant!(name: "Пустая точка", slug: "empty-point-debug", organization: @org)
    get "/shop/api/debug", headers: { "X-Shop-Tenant" => empty_tenant.id.to_s }
    assert_response :success
    data = response.parsed_body
    assert_equal [], data["products_for_tenant"]
    assert_equal [], data["product_tenant_settings"]
  end

  # ── Defense-in-depth: production guard ───────────────────────────────────────

  test "контроллер имеет before_action, блокирующий production (defense-in-depth)" do
    controller_class = Shop::Api::DebugController
    callbacks = controller_class._process_action_callbacks.select { |c| c.kind == :before }

    production_guard_present = callbacks.any? do |cb|
      cb.filter.is_a?(Proc) || cb.filter.to_s.include?("production")
    end
    assert production_guard_present, "DebugController должен иметь before_action с проверкой production"

    source_file = Rails.root.join("app/controllers/shop/api/debug_controller.rb").read
    assert_match(/before_action.*production\?/, source_file,
      "before_action должен содержать проверку Rails.env.production?")
    assert_match(/head\s+:not_found/, source_file,
      "before_action должен возвращать 404 в production")
  end
end
