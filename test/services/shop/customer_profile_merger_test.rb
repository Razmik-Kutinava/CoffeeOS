# frozen_string_literal: true

require "test_helper"

class Shop::CustomerProfileMergerTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @phone = "+7900#{rand(1000000..9999999)}"
    @email = "merge-#{SecureRandom.hex(3)}@example.com"
  end

  test "soft-merges donor into survivor: orders cards cart; donor inactive without contacts" do
    survivor = MobileCustomer.create!(
      phone: @phone,
      first_name: "Phone",
      is_active: true,
      phone_verified: true
    )
    donor = MobileCustomer.create!(
      email: @email,
      first_name: "Mail",
      is_active: true,
      email_verified: true
    )

    order = Order.create!(
      tenant: @tenant,
      customer_id: donor.id,
      order_number: "MRG-#{SecureRandom.hex(3)}",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    card = MobilePaymentMethod.create!(
      customer_id: donor.id,
      payment_type: "card",
      card_token: "rebill-merge-#{SecureRandom.hex(4)}",
      card_masked: "4300****0777",
      card_brand: "MIR",
      is_active: true,
      is_default: true
    )
    cart = MobileCart.create!(
      customer_id: donor.id,
      tenant_id: @tenant.id,
      items: [{ "product_id" => SecureRandom.uuid, "quantity" => 1 }],
      total_amount: 100
    )

    result = Shop::CustomerProfileMerger.merge!(survivor: survivor, donor: donor)

    assert_equal survivor.id, result.id
    survivor.reload
    donor.reload

    assert_equal @email, survivor.email
    assert survivor.email_verified
    assert_equal @phone, survivor.phone
    assert survivor.phone_verified

    assert_equal false, donor.is_active
    assert_nil donor.email
    assert_nil donor.phone
    assert_equal false, donor.email_verified
    assert_equal false, donor.phone_verified

    assert_equal survivor.id, order.reload.customer_id
    assert_equal survivor.id, card.reload.customer_id
    assert_equal survivor.id, cart.reload.customer_id
  end

  test "clean attach email without donor when email free" do
    survivor = MobileCustomer.create!(
      phone: @phone,
      first_name: "Phone",
      is_active: true,
      phone_verified: true
    )

    result = Shop::CustomerProfileMerger.link_email!(survivor: survivor, email: @email)

    assert_equal survivor.id, result.id
    assert_equal @email, survivor.reload.email
    assert survivor.email_verified
  end
end
