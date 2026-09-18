# frozen_string_literal: true

require "test_helper"

# TASK_93-C — Rack::Attack throttle GET /o/:hash
class RackAttackOrderShortLinkTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "o-atk-#{SecureRandom.hex(3)}")
    @customer = create_mobile_customer!(
      phone: "+79008200099",
      email: "oatk-#{SecureRandom.hex(3)}@example.com"
    )
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @customer.id,
      customer_name: "Atk",
      order_number: "202609-8299",
      source: :mobile,
      status: :ready,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100,
      ready_at: Time.current,
      ready_notified_at: Time.current
    )
    @hash = Shop::OrderReadySmsLink.hash_for(@order)
  end

  test "T-C4b under limit still redirects" do
    with_rack_attack do
      get "/o/#{@hash}", headers: { "REMOTE_ADDR" => "203.0.113.10" }
      assert_response :redirect
    end
  end

  test "T-C4a many GETs /o/ from same IP return 429" do
    with_rack_attack do
      ip = "203.0.113.11"
      30.times do
        get "/o/#{@hash}", headers: { "REMOTE_ADDR" => ip }
        assert_includes [ 302, 301, 404 ], response.status
      end

      get "/o/#{@hash}", headers: { "REMOTE_ADDR" => ip }
      assert_response :too_many_requests
    end
  end

  test "T-I4a shop/order_short_link/ip throttle rule exists" do
    assert Rack::Attack.throttles.key?("shop/order_short_link/ip")
  end

  test "T-I4b many GETs /o/ return 429 (shared-store ready)" do
    with_rack_attack do
      ip = "203.0.113.12"
      30.times do
        get "/o/#{@hash}", headers: { "REMOTE_ADDR" => ip }
        assert_includes [ 302, 301, 404 ], response.status
      end
      get "/o/#{@hash}", headers: { "REMOTE_ADDR" => ip }
      assert_response :too_many_requests
    end
  end

  test "T-I4c exactly one throttle path for /o/" do
    source = Rails.root.join("config/initializers/rack_attack.rb").read
    matches = source.scan(/throttle\([^)]*\)\s+do\s+\|req\|.*?start_with\?\("\/o\/"\)/m)
    # Fallback: count start_with?("/o/") inside throttle blocks
    o_paths = source.scan(/start_with\?\("\/o\/"\)/)
    assert_equal 1, o_paths.length, "expected one /o/ throttle discriminator, got #{o_paths.length}"
    names = source.scan(/throttle\("([^"]*order_short_link[^"]*)"/).flatten
    assert_equal [ "shop/order_short_link/ip" ], names.uniq
  end

end
