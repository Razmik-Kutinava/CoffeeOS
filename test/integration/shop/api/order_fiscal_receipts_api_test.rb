# frozen_string_literal: true

require "test_helper"

# #73 — fiscal RECEIPT webhook on /callbacks/tbank + order API
class Shop::Api::OrderFiscalReceiptsApiTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  setup do
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
    disable_rls!

    @tenant = create_tenant!(slug: "fiscal-lk-#{SecureRandom.hex(3)}")
    @category = create_category!
    @product = create_product!(category: @category, name: "Латте Fiscal")
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 300)
    @email = "fiscal-lk-#{SecureRandom.hex(4)}@example.com"
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
    Rails.cache.clear
  end

  def disable_rls!
    conn = ActiveRecord::Base.connection
    %w[orders payments fiscal_receipts].each do |table|
      next unless conn.table_exists?(table)

      conn.execute("ALTER TABLE #{conn.quote_table_name(table)} DISABLE ROW LEVEL SECURITY")
    end
  end

  def sign_payload(p)
    p.merge("Token" => Payments::TbankAdapter.new.build_token(p))
  end

  test "[TDD] RECEIPT notification returns plain OK and exposes receipt on order show" do
    open_session do |sess|
      sess.post "/shop/api/cart/add",
        headers: shop_tenant_headers(@tenant.id),
        params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
        as: :json
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)

      sess.post "/shop/api/orders",
        headers: shop_tenant_headers(@tenant.id),
        params: shop_order_params(email: @email, name: "Fiscal Guest", payment_method: "cash"),
        as: :json
      assert_equal 200, sess.response.status, sess.response.body
      order_id = sess.response.parsed_body["order_id"] || sess.response.parsed_body["id"]
      order = Order.find(order_id)
      order.update!(status: "accepted")

      # cash/shop: settled but OFD not expected → UI must not spin «Чек формируется»
      sess.get "/shop/api/orders/#{order_id}", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 200, sess.response.status
      body0 = sess.response.parsed_body
      assert_equal [], body0["fiscal_receipts"]
      assert_equal false, body0["fiscal_expected"]

      payment = order.payments.order(created_at: :desc).first!
      payment.update!(
        provider: "tbank",
        provider_payment_id: "fiscal_api_#{SecureRandom.hex(4)}",
        status: "succeeded",
        provider_data: (payment.provider_data || {}).merge("save_card" => false)
      )

      sess.get "/shop/api/orders/#{order_id}", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal true, sess.response.parsed_body["fiscal_expected"]
      assert_equal [], sess.response.parsed_body["fiscal_receipts"]

      payload = sign_payload(
        "TerminalKey" => "TestTerminal",
        "OrderId" => order.id.to_s,
        "Success" => true,
        "Status" => "RECEIPT",
        "PaymentId" => payment.provider_payment_id,
        "ErrorCode" => "0",
        "Amount" => (order.final_amount * 100).to_i,
        "FnNumber" => "9999078900009999",
        "FiscalDocumentNumber" => 55,
        "FiscalDocumentAttribute" => 66,
        "Type" => "Income",
        "Url" => "https://receipt.example/lk-check"
      )

      post "/callbacks/tbank",
        params: payload.to_json,
        headers: { "Content-Type" => "application/json" }
      assert_response :ok
      assert_equal "OK", response.body

      # retry
      post "/callbacks/tbank",
        params: payload.to_json,
        headers: { "Content-Type" => "application/json" }
      assert_response :ok
      assert_equal "OK", response.body
      assert_equal 1, FiscalReceipt.where(payment_id: payment.id).count

      sess.get "/shop/api/orders/#{order_id}", headers: shop_tenant_headers(@tenant.id), as: :json
      assert_equal 200, sess.response.status
      receipts = sess.response.parsed_body["fiscal_receipts"]
      assert_equal 1, receipts.length
      assert_equal "https://receipt.example/lk-check", receipts.first["url"]
      assert_equal "payment", receipts.first["operation_type"]
      assert_nil receipts.first["raw"]
      assert_nil receipts.first["receipt_data"]
    end
  end

  test "[TDD] payment CONFIRMED webhook still returns JSON ok (regression)" do
    order = Order.create!(
      tenant: @tenant,
      order_number: "ORD-REG-#{SecureRandom.hex(3)}",
      source: "mobile",
      status: "pending_payment",
      total_amount: 300,
      discount_amount: 0,
      final_amount: 300
    )
    payment = Payment.create!(
      order: order,
      tenant: @tenant,
      amount: 300,
      method: "card",
      provider: "tbank",
      provider_payment_id: "reg_#{SecureRandom.hex(4)}",
      status: "pending",
      provider_data: { "save_card" => false }
    )

    payload = sign_payload(
      "TerminalKey" => "TestTerminal",
      "OrderId" => order.id.to_s,
      "PaymentId" => payment.provider_payment_id,
      "Status" => "CONFIRMED",
      "Amount" => 30000
    )

    post "/callbacks/tbank",
      params: payload.to_json,
      headers: { "Content-Type" => "application/json" }
    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal true, body["ok"]
    assert_equal "succeeded", payment.reload.status
  end
end
