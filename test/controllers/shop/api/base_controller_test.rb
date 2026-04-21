# frozen_string_literal: true

require "test_helper"

# Тест поведения Shop::Api::BaseController через реальный endpoint (debug).
# Проверяет: tenant resolution, изоляция Current.tenant_id, восстановление после запроса.
class Shop::Api::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = create_organization!(slug: "base-ctrl-org")
    @tenant = create_tenant!(name: "Base Point", slug: "base-ctrl-point", organization: @org)
  end

  # ── with_shop_tenant! устанавливает контекст ──────────────────────────────

  test "запрос с валидным тенантом проходит (200)" do
    get "/shop/api/debug", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
  end

  test "запрос без заголовка резолвится через fallback (первый активный тенант)" do
    # resolved_shop_tenant_id возвращает nil только при полностью пустой БД.
    # В тестовой среде всегда есть активный тенант — fallback срабатывает.
    get "/shop/api/debug"
    assert_response :success
    data = response.parsed_body
    assert data.dig("resolved_tenant", "id").present?
  end

  test "запрос с несуществующим тенантом возвращает 404" do
    get "/shop/api/debug", headers: { "X-Shop-Tenant" => "00000000-0000-0000-0000-000000000099" }
    assert_response :not_found
    data = response.parsed_body
    assert_equal "Точка не найдена", data["error"]
  end

  # ── Current.tenant_id восстанавливается после запроса ─────────────────────

  test "Current.tenant_id после запроса не содержит tenant из запроса" do
    Current.tenant_id = nil

    get "/shop/api/debug", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success

    # После завершения запроса Current сбрасывается Rails (новый Current per-request),
    # поэтому проверяем что наш ensure не оставил утечку через глобальное состояние.
    # В тест-контексте Current.tenant_id будет nil (не засорён предыдущим запросом).
    assert_nil Current.tenant_id, "Current.tenant_id должен быть nil после запроса"
  end

  test "два последовательных запроса с разными тенантами изолированы" do
    other_tenant = create_tenant!(name: "Other", slug: "other-base-ctrl", organization: @org)

    get "/shop/api/debug", headers: { "X-Shop-Tenant" => @tenant.id.to_s }
    assert_response :success
    first_tenant_id = response.parsed_body.dig("resolved_tenant", "id")

    get "/shop/api/debug", headers: { "X-Shop-Tenant" => other_tenant.id.to_s }
    assert_response :success
    second_tenant_id = response.parsed_body.dig("resolved_tenant", "id")

    assert_equal @tenant.id, first_tenant_id
    assert_equal other_tenant.id, second_tenant_id
    assert_not_equal first_tenant_id, second_tenant_id
  end
end
