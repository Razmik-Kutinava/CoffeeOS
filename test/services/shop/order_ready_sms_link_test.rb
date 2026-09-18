# frozen_string_literal: true

require "test_helper"

# TASK_93-C — SMS short link host canon + HMAC (не мёртвый codeblack.xyz)
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
      final_amount: 100,
      ready_at: Time.current,
      ready_notified_at: Time.current
    )
    @prev_sms_host = ENV["SHOP_SMS_LINK_HOST"]
    @prev_app_host = ENV["APP_HOST"]
    ENV.delete("SHOP_SMS_LINK_HOST")
    ENV.delete("APP_HOST")
  end

  teardown do
    ENV["SHOP_SMS_LINK_HOST"] = @prev_sms_host
    ENV["APP_HOST"] = @prev_app_host
  end

  test "T-C1a sms_message_for uses configured host not hardcoded dead domain" do
    ENV["APP_HOST"] = "app.example.test"
    msg = Shop::OrderReadySmsLink.sms_message_for(@order)
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    assert_includes msg, "app.example.test/o/#{hash}"
    refute_includes msg, "codeblack.xyz"
  end

  test "T-C1b sms_message length within budget" do
    msg = Shop::OrderReadySmsLink.sms_message_for(@order)
    assert_operator msg.length, :<=, 70
  end

  test "T-C1c fallback host is coffeeos.fly.dev" do
    msg = Shop::OrderReadySmsLink.sms_message_for(@order)
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    assert_includes msg, "coffeeos.fly.dev/o/#{hash}"
    refute_includes msg, "codeblack.xyz"
  end

  test "SHOP_SMS_LINK_HOST wins over APP_HOST" do
    ENV["APP_HOST"] = "app.example.test"
    ENV["SHOP_SMS_LINK_HOST"] = "sms.example.test"
    msg = Shop::OrderReadySmsLink.sms_message_for(@order)
    assert_includes msg, "sms.example.test/o/"
    refute_includes msg, "app.example.test/o/"
  end

  test "hash_for is HMAC-bound and find_order roundtrips" do
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    assert hash.present?
    assert_operator hash.length, :<=, 32
    found = Shop::OrderReadySmsLink.find_order(hash)
    assert_equal @order.id, found.id
  end

  test "find_order rejects unsigned uuid-only hash" do
    uuid_hex = @order.id.to_s.delete("-")
    unsigned = Base64.urlsafe_encode64([ uuid_hex ].pack("H*"), padding: false)
    assert_nil Shop::OrderReadySmsLink.find_order(unsigned)
  end

  test "find_order returns nil for garbage" do
    assert_nil Shop::OrderReadySmsLink.find_order("not-a-hash!!")
  end

  test "T-C5a find_order returns nil when link TTL expired" do
    @order.update!(
      ready_notified_at: 49.hours.ago,
      ready_at: 49.hours.ago,
      updated_at: 49.hours.ago
    )
    hash = Shop::OrderReadySmsLink.hash_for(@order)
    assert_nil Shop::OrderReadySmsLink.find_order(hash)
  end
end
