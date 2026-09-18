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

  private

  def with_rack_attack
    was_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)
    yield
  ensure
    Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)
    Rack::Attack.enabled = was_enabled
  end
end
