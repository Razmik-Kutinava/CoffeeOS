# frozen_string_literal: true

require "test_helper"

class Shop::Api::B112R1NonpciTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "b112-r1-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @card = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      card_token: "rebill-r1-test",
      card_masked: "430000******5953",
      card_brand: "MIR",
      bank_card_id: "bank-card-1",
      card_expires_at: "12/28",
      payment_type: "card",
      is_active: true,
      is_default: true
    )
    @old_simulate = ENV["SHOP_SIMULATE_PAYMENT"]
    ENV["SHOP_SIMULATE_PAYMENT"] = "0"
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
    restore_tbank_adapter_new!
  end

  test "POST payments/new_card saves card on CONFIRMED FinishAuthorize" do
    stub_tbank_new_card!(finish_status: "CONFIRMED", rebill_id: "rebill-new-1", pan: "430000******5953")

    open_session do |sess|
      prepare_cart_and_email!(sess)

      sess.post "/shop/api/payments/new_card",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(email: @email, name: "R1 Guest", payment_method: "card").merge(
          card_data: "encrypted-card-data",
          save_card: true
        ),
        as: :json

      assert_equal 200, sess.response.status
      body = JSON.parse(sess.response.body)
      assert_equal "CONFIRMED", body["tbank_status"]
      assert_equal "0", body["error_code"]
      assert body["order_id"].present?
      assert_equal "rebill-new-1", MobilePaymentMethod.primary_for(@customer.id).card_token
      assert_equal "*5953", body.dig("saved_card", "pan")
    end
  end

  test "POST payments/new_card returns 3DS_CHECKING with ACS fields" do
    stub_tbank_new_card!(finish_status: "3DS_CHECKING", acs: true)

    open_session do |sess|
      prepare_cart_and_email!(sess)

      sess.post "/shop/api/payments/new_card",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(email: @email, name: "R1 Guest").merge(
          card_data: "encrypted-card-data",
          save_card: true
        ),
        as: :json

      assert_equal 200, sess.response.status
      body = JSON.parse(sess.response.body)
      assert_equal "3DS_CHECKING", body["tbank_status"]
      assert body.dig("three_ds", "acs_url").present?
      assert body.dig("three_ds", "pa_req").present?
    end
  end

  test "POST payments/new_card passes bank ErrorCode on failure" do
    stub_tbank_new_card!(finish_success: false, error_code: "1051", message: "Недостаточно средств")

    open_session do |sess|
      prepare_cart_and_email!(sess)

      sess.post "/shop/api/payments/new_card",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(email: @email, name: "R1 Guest").merge(card_data: "bad"),
        as: :json

      assert_equal 422, sess.response.status
      body = JSON.parse(sess.response.body)
      assert_equal "1051", body["error_code"]
    end
  end

  test "POST payments/one_click charges by card_id" do
    stub_tbank_one_click!(status: "CONFIRMED")

    open_session do |sess|
      prepare_cart_and_email!(sess)

      sess.post "/shop/api/payments/one_click",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(email: @email, name: "R1 Guest").merge(card_id: @card.id),
        as: :json

      assert_equal 200, sess.response.status
      body = JSON.parse(sess.response.body)
      assert body["recurrent_charge"]
      assert_equal "CONFIRMED", body["tbank_status"]
      assert_equal @card.id, body.dig("saved_card", "id")
      assert_equal "*5953", body.dig("saved_card", "pan")
    end
  end

  test "POST payments/one_click returns 3DS_CHECKING" do
    stub_tbank_one_click!(status: "3DS_CHECKING", acs: true)

    open_session do |sess|
      prepare_cart_and_email!(sess)

      sess.post "/shop/api/payments/one_click",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(email: @email, name: "R1 Guest").merge(card_id: @card.id),
        as: :json

      assert_equal 200, sess.response.status
      body = JSON.parse(sess.response.body)
      assert_equal "3DS_CHECKING", body["tbank_status"]
      assert body.dig("three_ds", "acs_url").present?
    end
  end

  test "POST payments/one_click passes bank ErrorCode" do
    stub_tbank_one_click_fail!(error_code: "1014", message: "Карта просрочена")

    open_session do |sess|
      prepare_cart_and_email!(sess)

      sess.post "/shop/api/payments/one_click",
        headers: { "X-Shop-Tenant" => @tenant.id.to_s },
        params: shop_order_params(email: @email, name: "R1 Guest").merge(card_id: @card.id),
        as: :json

      assert_equal 422, sess.response.status
      body = JSON.parse(sess.response.body)
      assert_equal "1014", body["error_code"]
    end
  end

  private

  def prepare_cart_and_email!(sess)
    sess.post "/shop/api/cart/add",
      headers: { "X-Shop-Tenant" => @tenant.id.to_s },
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
  end

  def restore_tbank_adapter_new!
    return unless defined?(@tbank_adapter_orig_new) && @tbank_adapter_orig_new

    Payments::TbankAdapter.define_singleton_method(:new, @tbank_adapter_orig_new)
  end

  def with_tbank_adapter_stub
    klass = Payments::TbankAdapter
    @tbank_adapter_orig_new ||= klass.method(:new)
    orig_new = @tbank_adapter_orig_new
    klass.define_singleton_method(:new) do
      inst = orig_new.call
      yield inst
      inst
    end
  end

  def stub_tbank_new_card!(finish_status: "CONFIRMED", finish_success: true, rebill_id: nil, pan: nil, error_code: "0", message: "", acs: false)
    with_tbank_adapter_stub do |inst|
      inst.define_singleton_method(:init_payment) do |**_kwargs|
        { payment_url: "https://pay.example/", provider_payment_id: "init-r1-1" }
      end
      inst.define_singleton_method(:finish_authorize) do |**_kwargs|
        if finish_success
          payload = {
            "Success" => true,
            "ErrorCode" => error_code,
            "Status" => finish_status,
            "PaymentId" => "init-r1-1",
            "RebillId" => rebill_id,
            "Pan" => pan,
            "CardId" => "card-bank-1",
            "ExpDate" => "1228"
          }
          if acs
            payload.merge!(
              "ACSUrl" => "https://acs.example/3ds",
              "PaReq" => "pareq",
              "MD" => "md-1"
            )
          end
          payload
        else
          { "Success" => false, "ErrorCode" => error_code, "Message" => message }
        end
      end
    end
  end

  def stub_tbank_one_click!(status: "CONFIRMED", acs: false)
    with_tbank_adapter_stub do |inst|
      inst.define_singleton_method(:charge_recurrent) do |**_kwargs|
        charge = {
          "Success" => true,
          "ErrorCode" => "0",
          "Status" => status,
          "PaymentId" => "charge-r1-1"
        }
        if acs
          charge.merge!(
            "ACSUrl" => "https://acs.example/3ds",
            "PaReq" => "pareq",
            "MD" => "md-2"
          )
        end
        {
          provider_payment_id: "charge-r1-1",
          charged: true,
          charge_response: charge,
          status: status
        }
      end
      inst.define_singleton_method(:get_payment_state) do |**|
        { "Success" => true, "ErrorCode" => "0", "Status" => "CONFIRMED", "PaymentId" => "charge-r1-1" }
      end
    end
  end

  def stub_tbank_one_click_fail!(error_code:, message:)
    with_tbank_adapter_stub do |inst|
      inst.define_singleton_method(:charge_recurrent) do |**_kwargs|
        raise Payments::TbankAdapter::ApiError.new(error_code: error_code, message: message)
      end
    end
  end
end
