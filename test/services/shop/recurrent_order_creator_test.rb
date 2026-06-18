# frozen_string_literal: true

require "test_helper"

class Shop::RecurrentOrderCreatorTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    category = create_category!
    @product = create_product!(category: category)
    enable_product_for_tenant!(tenant: @tenant, product: @product, price: 179)
    @email = "recurrent-unit-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    @card = MobilePaymentMethod.create!(
      customer_id: @customer.id,
      card_token: "rebill-unit",
      card_masked: "430000******0777",
      card_brand: "Visa",
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
    Current.reset
    ENV["SHOP_SIMULATE_PAYMENT"] = @old_simulate
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  test "charges saved card and sets provider_payment_id" do
    klass = Payments::TbankAdapter
    orig_new = klass.method(:new)
    klass.define_singleton_method(:new) do
      inst = orig_new.call
      inst.define_singleton_method(:charge_recurrent) do |**_kwargs|
        { provider_payment_id: "charge-unit-1", charged: true }
      end
      inst
    end

    post "/shop/api/cart/add",
      headers: shop_tenant_headers(@tenant.id),
      params: { product_id: @product.id, quantity: 1, selected_modifiers: [] },
      as: :json
    verify_shop_email!(tenant_id: @tenant.id, email: @email)

    creator = Shop::RecurrentOrderCreator.new(session, tenant: @tenant, request: @request)
    order = creator.call!(
      email: @email,
      name: "Unit Guest",
      payment_method: "card",
      saved_card_id: @card.id
    )

    assert_equal "charge-unit-1", creator.provider_payment_id
    assert order.pending_payment?
    payment = order.payments.last
    assert_equal "charge-unit-1", payment.provider_payment_id
  ensure
    klass.define_singleton_method(:new, orig_new)
  end
end
