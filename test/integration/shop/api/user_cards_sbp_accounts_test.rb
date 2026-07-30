# frozen_string_literal: true

require "test_helper"

# #34 Checkout UI: GET user/cards отдаёт sbp_accounts.
class Shop::Api::UserCardsSbpAccountsTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @email = "sbp-ui-#{SecureRandom.hex(3)}@example.com"
    @customer = create_mobile_customer!(email: @email)
  end

  teardown { Current.reset }

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  test "GET user/cards includes sbp_accounts and has_sbp_account" do
    MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "sbp",
      card_token: "acct-ui-1",
      card_masked: "СБП",
      is_active: true,
      is_default: true
    )
    MobilePaymentMethod.create!(
      customer_id: @customer.id,
      payment_type: "card",
      card_token: "rebill-ui",
      card_masked: "*1234",
      card_brand: "MIR",
      card_expires_at: "12/30",
      is_active: true,
      is_default: true
    )

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, @customer.id)

      sess.get "/shop/api/user/cards",
        headers: shop_headers,
        params: { email: @email }

      assert_equal 200, sess.response.status, sess.response.body
      body = JSON.parse(sess.response.body)
      assert body["has_sbp_account"]
      assert_equal 1, body["sbp_accounts"].length
      assert_equal "Ваш счет СБП", body["sbp_accounts"][0]["label"]
      assert_equal "sbp", body["sbp_accounts"][0]["payment_type"]
      assert body["cards"].length >= 1
    end
  end

  test "Checkout and sheet wire sbp account UI hooks" do
    src = Rails.root.join("app/frontend/routes/Checkout.svelte").read
    sheet = Rails.root.join("app/frontend/components/PaymentMethodsSheet.svelte").read
    i18n = Rails.root.join("app/frontend/lib/paymentMethodI18n.js").read
    assert_match(/sbpAccounts|saveSbpAccount|sbp_account|chargeSbpAutopay/, src)
    assert_match(/payment-method-sbp-account|save-sbp-account-checkbox|labelSbpAccount|labelBindSbpAccount/, sheet)
    assert_match(/Ваш счет СБП/, i18n)
    assert_match(/Привязать счет/, i18n)
  end
end
