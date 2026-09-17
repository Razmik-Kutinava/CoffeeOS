# frozen_string_literal: true

require "test_helper"

# #82 Патч_1 — короткий order_hash для SMS codeblack.xyz/o/{hash}
class Shop::OrderReadySmsLinkTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_name: "Link",
      order_number: "202609-8201",
      source: :mobile,
      status: :ready,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
  end

  test "#82 P1 hash_for is short enough for SMS prefix + hash <= 70" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    msg = "CODE:BLACK. Заказ готов! codeblack.xyz/o/#{hash}"
    assert hash.present?
    assert_operator hash.length, :<=, 22
    assert_operator msg.length, :<=, 70
  end

  test "#82 P1 find_order roundtrips hash to order" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    found = Shop::OrderReadySmsLink.find_order(hash)
    assert_equal @order.id, found.id
  end

  test "#82 P1 find_order returns nil for garbage" do
    assert_nil Shop::OrderReadySmsLink.find_order("not-a-hash!!")
  end
end
