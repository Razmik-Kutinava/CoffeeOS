# frozen_string_literal: true

require "test_helper"

# Задача-2: amount_rub в GET /shop/api/user/cards = promo_amount_rub точки.
class Shop::Api::UserCardsControllerTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @email = "promo-amount-#{SecureRandom.hex(3)}@example.com"
    @customer = create_mobile_customer!(email: @email)
    PointCampaignSetting.create!(
      point_id: @tenant.id,
      campaign_type: PointCampaignSetting::CAMPAIGN_CARD_BINDING_PROMO,
      enabled: true,
      threshold: 1000,
      counter: 0,
      config: { "promo_amount_rub" => 11 }
    )
  end

  teardown { Current.reset }

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  test "growth_promo.amount_rub follows promo_amount_rub=15 from point config" do
    setting = PointCampaignSetting.card_binding_promo_for(@tenant.id)
    setting.update!(config: { "promo_amount_rub" => 15 })

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, @customer.id)

      sess.get "/shop/api/user/cards", headers: shop_headers, as: :json

      assert_equal 200, sess.response.status, sess.response.body
      body = JSON.parse(sess.response.body)
      assert_equal 15, body.dig("growth_promo", "amount_rub")
    end
  end

  test "growth_promo.amount_rub defaults to 11 when promo_amount_rub absent" do
    setting = PointCampaignSetting.card_binding_promo_for(@tenant.id)
    setting.update!(config: {})

    open_session do |sess|
      verify_shop_email!(tenant_id: @tenant.id, email: @email, session: sess)
      Shop::CustomerSession.set_customer_id!(sess.session, @tenant.id, @customer.id)

      sess.get "/shop/api/user/cards", headers: shop_headers, as: :json

      assert_equal 200, sess.response.status, sess.response.body
      body = JSON.parse(sess.response.body)
      assert_equal PointCampaignSetting::DEFAULT_PROMO_AMOUNT_RUB, body.dig("growth_promo", "amount_rub")
    end
  end

  test "anonymous growth_promo.amount_rub uses tenant promo_amount_rub" do
    setting = PointCampaignSetting.card_binding_promo_for(@tenant.id)
    setting.update!(config: { "promo_amount_rub" => 15 })

    get "/shop/api/user/cards", headers: shop_headers, as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal false, body.dig("growth_promo", "eligible")
    assert_equal 15, body.dig("growth_promo", "amount_rub")
  end
end
