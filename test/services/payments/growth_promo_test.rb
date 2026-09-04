# frozen_string_literal: true

require "test_helper"

# #75 [TDD][RED] промо 11₽: eligibility, сумма, дедуп phone/method_hash, без траты права без чекбокса.
class Payments::GrowthPromoTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @phone = "+7900#{format('%07d', rand(10_000_000))}"
    @customer = create_mobile_customer!(phone: @phone, email: "growth-#{SecureRandom.hex(3)}@example.com")
  end

  teardown do
    Current.reset
  end

  test "GROWTH_AMOUNT_RUB is 11" do
    assert_equal 11, Payments::GrowthPromo::AMOUNT_RUB
  end

  test "eligible when point allows, no prior growth for phone, bind requested" do
    assert Payments::GrowthPromo.eligible?(
      tenant: @tenant,
      customer: @customer,
      bind_requested: true
    )
  end

  test "not eligible when bind_requested is false (checkbox off keeps right)" do
    refute Payments::GrowthPromo.eligible?(
      tenant: @tenant,
      customer: @customer,
      bind_requested: false
    )
  end

  test "charge_amount returns 11 when eligible and bind requested" do
    amount = Payments::GrowthPromo.charge_amount(
      cart_total: 450,
      tenant: @tenant,
      customer: @customer,
      bind_requested: true
    )
    assert_equal 11, amount
  end

  test "price! keeps chk_order_amounts identity when growth applies" do
    priced = Payments::GrowthPromo.price!(
      subtotal: 450,
      discount: 0,
      tenant: @tenant,
      customer: @customer,
      bind_requested: true
    )
    assert priced[:growth_intent]
    assert_equal 11, priced[:final_amount]
    assert_equal 439, priced[:discount_amount]
    assert_equal priced[:final_amount], 450 - priced[:discount_amount]
  end

  test "price! without bind keeps full cart" do
    priced = Payments::GrowthPromo.price!(
      subtotal: 450,
      discount: 0,
      tenant: @tenant,
      customer: @customer,
      bind_requested: false
    )
    refute priced[:growth_intent]
    assert_equal 450, priced[:final_amount]
    assert_equal 0, priced[:discount_amount]
  end

  test "charge_amount returns full cart when checkbox off" do
    amount = Payments::GrowthPromo.charge_amount(
      cart_total: 450,
      tenant: @tenant,
      customer: @customer,
      bind_requested: false
    )
    assert_equal 450, amount
  end

  test "after successful growth by phone promo is not offered again (card or sbp)" do
    Payments::GrowthPromo.mark_used!(
      phone: @phone,
      method_hash: "hash-sbp-1",
      method_type: "sbp",
      customer_id: @customer.id,
      tenant_id: @tenant.id
    )

    refute Payments::GrowthPromo.eligible?(
      tenant: @tenant,
      customer: @customer,
      bind_requested: true
    )
  end

  test "method_hash that already had growth blocks promo even for new phone" do
    Payments::GrowthPromo.mark_used!(
      phone: @phone,
      method_hash: "hash-card-shared",
      method_type: "card",
      customer_id: @customer.id,
      tenant_id: @tenant.id
    )

    other_phone = "+7901#{format('%07d', rand(10_000_000))}"
    other = create_mobile_customer!(phone: other_phone, email: "growth-mh-#{SecureRandom.hex(3)}@example.com")

    refute Payments::GrowthPromo.eligible?(
      tenant: @tenant,
      customer: other,
      bind_requested: true,
      method_hash: "hash-card-shared"
    )
  end

  test "failed payment must not consume promo right" do
    # mark_used! only on success — recording failed attempt must leave eligible
    CardBindingAttempt.record!(
      method_type: "card",
      method_hash: "hash-fail-1",
      phone: @phone,
      account_id: @customer.id,
      result: "payment_failed",
      is_growth_event: false,
      point_id: @tenant.id
    )

    assert Payments::GrowthPromo.eligible?(
      tenant: @tenant,
      customer: @customer,
      bind_requested: true
    )
  end
end
