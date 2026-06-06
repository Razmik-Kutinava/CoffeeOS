# frozen_string_literal: true

require "test_helper"

class Platform::TenantTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    org = create_organization!
    anchor = create_tenant!(organization: org, slug: "tx-anchor-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: anchor,
      organization: org,
      role_codes: %w[ук_global_admin],
      email: "uk-tx-#{SecureRandom.hex(3)}@test.local",
      password: "pass123"
    )
    @tenant = create_tenant!(organization: org, name: "Tx Point", slug: "tx-t-#{SecureRandom.hex(3)}")
    order = Order.create!(
      tenant: @tenant,
      order_number: "TX-100",
      source: "mobile",
      status: "accepted",
      total_amount: 179,
      discount_amount: 0,
      final_amount: 179
    )
    Payment.create!(
      tenant: @tenant,
      order: order,
      amount: 179,
      method: "card",
      provider: "tbank",
      status: "succeeded",
      provider_payment_id: "fly-pay-999"
    )
  end

  test "redirects guest to login" do
    get platform_monitoring_tenant_transactions_path(@tenant)
    assert_redirected_to login_path
  end

  test "uk admin sees transactions page" do
    login_as!(@uk)
    get platform_monitoring_tenant_transactions_path(@tenant)
    assert_response :success
    assert_includes response.body, "Транзакции"
    assert_includes response.body, "TX-100"
    assert_includes response.body, "fly-pay-999"
    assert_includes response.body, "▸ JSON"
  end

  test "uk admin gets transactions json" do
    login_as!(@uk)
    get platform_monitoring_tenant_transactions_path(@tenant, format: :json)
    assert_response :success
    data = JSON.parse(response.body)
    assert data.key?("payments")
    assert data.key?("summary")
    assert_equal "fly-pay-999", data["payments"].first["provider_payment_id"]
  end

  test "health transactions json" do
    login_as!(@uk)
    get transactions_health_tenant_path(@tenant)
    assert_response :success
    data = JSON.parse(response.body)
    assert data.key?("payments")
  end
end
