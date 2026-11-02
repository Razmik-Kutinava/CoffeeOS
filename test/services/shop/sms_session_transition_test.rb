# frozen_string_literal: true

require "test_helper"

# TASK_117 — безопасная смена клиентской сессии по SMS-ссылке [TDD]
class Shop::SmsSessionTransitionTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!(slug: "sms-tr-#{SecureRandom.hex(3)}")
    @owner = create_mobile_customer!(phone: "+79001170001", email: "owner-#{SecureRandom.hex(3)}@example.com")
    @other = create_mobile_customer!(phone: "+79001170002", email: "other-#{SecureRandom.hex(3)}@example.com")
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: @owner.id,
      customer_name: "Owner",
      order_number: "SMS-117-1",
      source: :mobile,
      status: :ready,
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150,
      ready_at: Time.current,
      ready_notified_at: Time.current
    )
  end

  test "conflict? false when session has no customer for order tenant" do
    session = {}
    refute Shop::SmsSessionTransition.conflict?(session, @order)
  end

  test "conflict? false when session customer matches order owner" do
    session = {}
    Shop::CustomerSession.set_customer_id!(session, @tenant.id, @owner.id)
    refute Shop::SmsSessionTransition.conflict?(session, @order)
  end

  test "conflict? true when another customer already bound for order tenant" do
    session = {}
    Shop::CustomerSession.set_customer_id!(session, @tenant.id, @other.id)
    assert Shop::SmsSessionTransition.conflict?(session, @order)
  end

  test "pending_token_for round-trips order without binding session" do
    session = {}
    Shop::CustomerSession.set_customer_id!(session, @tenant.id, @other.id)
    token = Shop::SmsSessionTransition.pending_token_for(@order)
    assert token.present?

    found = Shop::SmsSessionTransition.order_from_pending!(token)
    assert_equal @order.id, found.id
    assert_equal @other.id.to_s, Shop::CustomerSession.customer_id(session, @tenant.id)
  end

  test "confirm! binds owner, clears cart, keeps other tenants customers" do
    session = {}
    other_tenant = create_tenant!(slug: "sms-tr-b-#{SecureRandom.hex(3)}")
    Shop::CustomerSession.set_customer_id!(session, @tenant.id, @other.id)
    Shop::CustomerSession.set_customer_id!(session, other_tenant.id, @other.id)
    session[Shop::CartService::SESSION_KEY] = [
      { "product_id" => SecureRandom.uuid, "quantity" => 1, "selected_modifiers" => [] }
    ]
    session[Shop::CartService::TENANT_SESSION_KEY] = @tenant.id.to_s

    token = Shop::SmsSessionTransition.pending_token_for(@order)
    bound = Shop::SmsSessionTransition.confirm!(session, token: token)

    assert_equal @order.id, bound.id
    assert_equal @owner.id.to_s, Shop::CustomerSession.customer_id(session, @tenant.id)
    assert_equal @other.id.to_s, Shop::CustomerSession.customer_id(session, other_tenant.id),
                 "клиент другой точки в сессии не меняется"
    assert_empty session[Shop::CartService::SESSION_KEY]
  end

  test "decline! does not bind or clear cart" do
    session = {}
    Shop::CustomerSession.set_customer_id!(session, @tenant.id, @other.id)
    session[Shop::CartService::SESSION_KEY] = [
      { "product_id" => SecureRandom.uuid, "quantity" => 2, "selected_modifiers" => [] }
    ]
    session[Shop::CartService::TENANT_SESSION_KEY] = @tenant.id.to_s
    token = Shop::SmsSessionTransition.pending_token_for(@order)

    assert Shop::SmsSessionTransition.decline!(session, token: token)
    assert_equal @other.id.to_s, Shop::CustomerSession.customer_id(session, @tenant.id)
    assert_equal 1, session[Shop::CartService::SESSION_KEY].size
  end

  test "confirm! rejects tampered pending token" do
    session = {}
    Shop::CustomerSession.set_customer_id!(session, @tenant.id, @other.id)
    token = Shop::SmsSessionTransition.pending_token_for(@order)

    assert_nil Shop::SmsSessionTransition.confirm!(session, token: "#{token}x")
    assert_equal @other.id.to_s, Shop::CustomerSession.customer_id(session, @tenant.id)
  end
end
