# frozen_string_literal: true

require "test_helper"

# TASK_111 [TDD][RED] Subtask 3c: булево pwa_installed в GET /shop/api/profile, дата установки не отдаётся.
class Shop::Api::ProfilePwaInstalledTest < ActionDispatch::IntegrationTest
  include TestFactories
  include ShopEmailTestHelper

  PREVIOUS_KEYS = %w[
    id email email_verified receipt_email phone phone_verified first_name last_name name
    balance points discount_percent orders_count favorites_count
    eligible_for_subscription_offer should_show_banner has_unread_offer_in_lk
  ].freeze

  setup do
    @tenant = create_tenant!
    @email = "pwa-#{SecureRandom.hex(4)}@example.com"
    @customer = create_mobile_customer!(email: @email)
  end

  def profile_for(sess)
    verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
    sess.get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id), as: :json
    assert_equal 200, sess.response.status, sess.response.body
    sess.response.parsed_body
  end

  test "Subtask 3c: not installed → pwa_installed false, no install date" do
    open_session do |sess|
      body = profile_for(sess)
      assert_equal false, body["pwa_installed"]
      assert_not body.key?("pwa_installed_at")
    end
  end

  test "Subtask 3c: pwa_installed_at set → pwa_installed true, no install date" do
    @customer.update!(pwa_installed_at: 2.days.ago)
    open_session do |sess|
      body = profile_for(sess)
      assert_equal true, body["pwa_installed"]
      assert_not body.key?("pwa_installed_at")
    end
  end

  test "Subtask 3c: previous profile fields unchanged" do
    open_session do |sess|
      body = profile_for(sess)
      assert_equal (PREVIOUS_KEYS + %w[pwa_installed]).sort, body.keys.sort
    end
  end

  test "Subtask 3c: guest without login still 401" do
    get "/shop/api/profile", headers: shop_tenant_headers(@tenant.id), as: :json
    assert_response :unauthorized
    assert_not response.parsed_body.key?("pwa_installed")
  end

  test "Subtask 3c: session/refresh profile not changed" do
    src = File.read(Rails.root.join("app/services/shop/session_refresh.rb"))
    assert_not_includes src, "pwa_installed"
  end
end
