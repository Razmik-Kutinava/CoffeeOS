# frozen_string_literal: true

require "test_helper"

# #77 [TDD][RED] УК CRUD subscription_offer_settings
class Platform::SubscriptionOfferSettingsControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @org = create_organization!
    @anchor = create_tenant!(organization: @org, slug: "anchor-#{SecureRandom.hex(3)}")
    @point = create_tenant!(organization: @org, slug: "point-#{SecureRandom.hex(3)}")
    @uk = create_user!(
      tenant: @anchor,
      organization: @org,
      role_codes: %w[ук_global_admin],
      email: "uk-offer-#{SecureRandom.hex(4)}@test.local",
      password: "pass123"
    )
    login_as!(@uk)
  end

  test "show returns defaults when settings absent" do
    get "/admin/tenants/#{@point.id}/subscription_offer_setting"
    assert_response :success
    body = response.parsed_body
    assert_equal false, body["enabled"]
    assert_equal "tips", body["second_cta_mode"]
    assert_equal 1, body["min_completed_orders"]
    assert_equal 1, body["required_signals_count"]
  end

  test "update saves point-scoped settings and validates range" do
    patch "/admin/tenants/#{@point.id}/subscription_offer_setting",
      params: {
        subscription_offer_setting: {
          enabled: true,
          second_cta_mode: "subscription",
          min_completed_orders: 2,
          required_signals_count: 2
        }
      },
      as: :json

    assert_response :success, response.body
    setting = SubscriptionOfferSetting.find_by!(point_id: @point.id)
    assert setting.enabled?
    assert_equal "subscription", setting.second_cta_mode
    assert_equal 2, setting.min_completed_orders
    assert_equal 2, setting.required_signals_count

    other = create_tenant!(organization: @org, slug: "iso-#{SecureRandom.hex(3)}")
    assert_nil SubscriptionOfferSetting.find_by(point_id: other.id)

    patch "/admin/tenants/#{@point.id}/subscription_offer_setting",
      params: {
        subscription_offer_setting: {
          enabled: true,
          second_cta_mode: "subscription",
          min_completed_orders: 1,
          required_signals_count: 9
        }
      },
      as: :json
    assert_response :bad_request
  end

  test "edit html form for UK" do
    get "/admin/tenants/#{@point.id}/subscription_offer_setting/edit"
    assert_response :success
    assert_match(/Подписка|subscription|оффер/i, response.body)
  end
end
