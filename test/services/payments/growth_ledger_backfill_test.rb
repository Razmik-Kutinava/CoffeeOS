# frozen_string_literal: true

require "test_helper"

# TASK_102 / #75 Патч 1: единый журнал права на промо 11₽ — backfill legacy saved methods
# + запись при сохранении без промо. Eligibility читает только card_binding_attempts.
class Payments::GrowthLedgerBackfillTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    PointCampaignSetting.create!(
      point_id: @tenant.id,
      campaign_type: PointCampaignSetting::CAMPAIGN_CARD_BINDING_PROMO,
      enabled: true,
      threshold: 1000,
      counter: 0,
      config: { "promo_amount_rub" => 11 }
    )
    @phone = "+7903#{format('%07d', rand(10_000_000))}"
    @customer = create_mobile_customer!(phone: @phone, email: "ledger-#{SecureRandom.hex(3)}@example.com")
  end

  teardown { Current.reset }

  test "Subtask 9: saved method without ledger record is not a runtime criterion (before backfill)" do
    legacy_card!(@customer, card_id: "legacy-before-#{SecureRandom.hex(3)}")

    assert Payments::GrowthPromo.available?(@customer, @tenant),
      "до backfill eligibility читает только журнал, MobilePaymentMethod напрямую не проверяется"
  end

  test "Subtask 3 + 6: legacy card backfilled blocks promo" do
    card = legacy_card!(@customer, card_id: "legacy-card-#{SecureRandom.hex(3)}")

    Payments::GrowthLedgerBackfill.run!

    row = CardBindingAttempt.find_by(source: "backfill_pre_promo", method_hash: card.card_hash)
    assert row, "ожидается backfill-запись для карты"
    assert row.is_growth_event
    assert_equal "card", row.method_type
    assert_equal CardBindingAttempt.phone_digest_for(@phone), row.phone_digest
    assert_equal @customer.id, row.account_id
    assert_nil row.phone
    refute Payments::GrowthPromo.available?(@customer, @tenant)
    refute Payments::GrowthPromo.eligible?(tenant: @tenant, customer: @customer, bind_requested: true)
  end

  test "Subtask 4 + 7: legacy SBP backfilled blocks promo" do
    sbp = legacy_sbp!(@customer, token: "acct-legacy-#{SecureRandom.hex(3)}")

    Payments::GrowthLedgerBackfill.run!

    row = CardBindingAttempt.find_by(source: "backfill_pre_promo", method_hash: sbp.card_hash)
    assert row, "ожидается backfill-запись для СБП"
    assert_equal "sbp", row.method_type
    refute Payments::GrowthPromo.available?(@customer, @tenant)
  end

  test "Subtask 3: card without card_hash is covered by phone digest only" do
    MobilePaymentMethod.create!(
      customer_id: @customer.id, payment_type: "card",
      card_token: "rebill-nohash-#{SecureRandom.hex(3)}", card_masked: "4300 **** 1111", is_active: true
    )

    Payments::GrowthLedgerBackfill.run!

    row = CardBindingAttempt.find_by(source: "backfill_pre_promo", account_id: @customer.id)
    assert row
    assert_nil row.method_hash
    refute Payments::GrowthPromo.available?(@customer, @tenant)
  end

  test "Subtask 5: backfill is idempotent" do
    legacy_card!(@customer, card_id: "legacy-idem-#{SecureRandom.hex(3)}")
    legacy_sbp!(@customer, token: "acct-idem-#{SecureRandom.hex(3)}")

    Payments::GrowthLedgerBackfill.run!
    first = CardBindingAttempt.where(account_id: @customer.id).order(:created_at).pluck(:id, :updated_at)

    Payments::GrowthLedgerBackfill.run!
    second = CardBindingAttempt.where(account_id: @customer.id).order(:created_at).pluck(:id, :updated_at)

    assert_equal first, second
    assert_equal 2, first.size
  end

  test "backfill skips methods already covered by a real growth event" do
    card = legacy_card!(@customer, card_id: "legacy-covered-#{SecureRandom.hex(3)}")
    Payments::GrowthPromo.mark_used!(
      phone: @phone, method_hash: card.card_hash, method_type: "card",
      customer_id: @customer.id, tenant_id: @tenant.id
    )

    assert_no_difference -> { CardBindingAttempt.count } do
      Payments::GrowthLedgerBackfill.run!
    end
  end

  test "backfill does not consume point campaign counter" do
    setting = PointCampaignSetting.card_binding_promo_for(@tenant.id)
    setting.update!(threshold: 1)
    legacy_card!(@customer, card_id: "legacy-counter-#{SecureRandom.hex(3)}")

    Payments::GrowthLedgerBackfill.run!

    assert_nil CardBindingAttempt.find_by(source: "backfill_pre_promo", account_id: @customer.id).point_id
    assert_equal 0, CardBindingAttempt.growth_count_for_point(@tenant.id)
    other = create_mobile_customer!(email: "ledger-other-#{SecureRandom.hex(3)}@example.com")
    assert Payments::GrowthPromo.available?(other, @tenant), "лимит точки не должен съедаться backfill-ом"
  end

  test "backfill includes inactive methods and skips ya_pay" do
    legacy_card!(@customer, card_id: "legacy-inactive-#{SecureRandom.hex(3)}").update_columns(is_active: false)
    ya_customer = create_mobile_customer!(email: "ledger-ya-#{SecureRandom.hex(3)}@example.com")
    MobilePaymentMethod.create!(customer_id: ya_customer.id, payment_type: "ya_pay", card_token: "ya-1", is_active: true)

    Payments::GrowthLedgerBackfill.run!

    refute Payments::GrowthPromo.available?(@customer, @tenant), "удалённая карта не возвращает право"
    assert_nil CardBindingAttempt.find_by(account_id: ya_customer.id)
  end

  test "dry_run reports count and writes nothing" do
    legacy_card!(@customer, card_id: "legacy-dry-#{SecureRandom.hex(3)}")

    result = nil
    assert_no_difference -> { CardBindingAttempt.count } do
      result = Payments::GrowthLedgerBackfill.run!(dry_run: true)
    end
    assert_operator result[:to_create], :>=, 1
  end

  test "Subtask 14: legacy card + backfill -> first SBP save gives no promo" do
    legacy_card!(@customer, card_id: "legacy-c2s-#{SecureRandom.hex(3)}")
    Payments::GrowthLedgerBackfill.run!

    refute Payments::GrowthPromo.eligible?(
      tenant: @tenant, customer: @customer, bind_requested: true,
      method_hash: Payments::SbpAccountTokenStore.method_hash_for("acct-new-#{SecureRandom.hex(3)}")
    )
  end

  test "Subtask 15: legacy SBP + backfill -> first card save gives no promo" do
    legacy_sbp!(@customer, token: "acct-s2c-#{SecureRandom.hex(3)}")
    Payments::GrowthLedgerBackfill.run!

    refute Payments::GrowthPromo.eligible?(
      tenant: @tenant, customer: @customer, bind_requested: true,
      method_hash: Payments::SavedCardStore.card_hash_for("card-new-#{SecureRandom.hex(3)}")
    )
  end

  test "Subtask 10: price! charges full cart when ledger covers phone even with bind_requested" do
    legacy_card!(@customer, card_id: "legacy-price-#{SecureRandom.hex(3)}")
    Payments::GrowthLedgerBackfill.run!

    priced = Payments::GrowthPromo.price!(
      subtotal: 450, discount: 0, tenant: @tenant, customer: @customer, bind_requested: true
    )
    refute priced[:growth_intent]
    assert_equal 450.to_d, priced[:final_amount]
  end

  test "Subtask 17: order history alone does not change eligibility" do
    Order.create!(
      tenant_id: @tenant.id, customer_id: @customer.id, customer_name: "History",
      order_number: "", source: :mobile, status: :closed,
      total_amount: 200, discount_amount: 0, final_amount: 200
    )
    Payments::GrowthLedgerBackfill.run!

    assert Payments::GrowthPromo.available?(@customer, @tenant)
  end

  # --- Subtask 18: сохранение без промо закрывает право ---

  test "Subtask 18: card saved without promo intent writes saved_without_promo ledger record" do
    card = persist_card!(@customer, card_id: "card-nopromo-#{SecureRandom.hex(3)}", provider_data: { "save_card" => true })

    row = CardBindingAttempt.find_by(source: "saved_without_promo", method_hash: card.card_hash)
    assert row, "сохранение без промо должно попасть в журнал"
    assert row.is_growth_event
    assert_nil row.point_id
    assert_equal 0, CardBindingAttempt.growth_count_for_point(@tenant.id)
    refute Payments::GrowthPromo.available?(@customer, @tenant)
  end

  test "Subtask 11: real growth (11 rub) writes one point growth record, no saved_without_promo" do
    card = persist_card!(
      @customer, card_id: "card-growth-#{SecureRandom.hex(3)}",
      provider_data: { "save_card" => true, "growth_promo_intent" => true }
    )

    growth = CardBindingAttempt.where(is_growth_event: true, method_hash: card.card_hash)
    assert_equal 1, growth.count
    assert_nil growth.first.source
    assert_equal @tenant.id, growth.first.point_id
    assert_equal 1, CardBindingAttempt.growth_count_for_point(@tenant.id)
  end

  test "Subtask 18: SBP saved without promo writes saved_without_promo ledger record" do
    payment = sbp_payment!(@customer, provider_data: { "save_sbp_account" => true })
    autopay = Object.new
    autopay.define_singleton_method(:get_add_account_qr_state) { |request_key:| { account_token: "acct-nopromo-#{request_key}" } }

    stored = Payments::SbpAccountTokenFromWebhook.new(autopay: autopay).call!(
      payment: payment,
      payload: { "Status" => "CONFIRMED", "RequestKey" => "rk-#{SecureRandom.hex(3)}" }
    )

    row = CardBindingAttempt.find_by(source: "saved_without_promo", method_hash: stored.method_hash)
    assert row
    assert_equal "sbp", row.method_type
    assert_nil row.point_id
    refute Payments::GrowthPromo.available?(@customer, @tenant)
  end

  test "Subtask 18: re-saving an already covered method adds no ledger rows" do
    card_id = "card-resave-#{SecureRandom.hex(3)}"
    persist_card!(@customer, card_id: card_id, provider_data: { "save_card" => true })

    assert_no_difference -> { CardBindingAttempt.where(is_growth_event: true).count } do
      persist_card!(@customer, card_id: card_id, provider_data: { "save_card" => true })
    end
  end

  private

  def legacy_card!(customer, card_id:)
    MobilePaymentMethod.create!(
      customer_id: customer.id, payment_type: "card",
      card_token: "rebill-#{card_id}", bank_card_id: card_id,
      card_hash: Payments::SavedCardStore.card_hash_for(card_id),
      card_masked: "4300 **** 1111", is_active: true
    )
  end

  def legacy_sbp!(customer, token:)
    MobilePaymentMethod.create!(
      customer_id: customer.id, payment_type: "sbp",
      card_token: token, card_hash: Payments::SbpAccountTokenStore.method_hash_for(token),
      card_masked: "СБП", card_brand: "SBP", is_active: true
    )
  end

  def new_order!(customer)
    Order.create!(
      tenant_id: @tenant.id, customer_id: customer.id, customer_name: "Ledger Guest",
      order_number: "", source: :mobile, status: :accepted,
      total_amount: 100, discount_amount: 0, final_amount: 100
    )
  end

  def persist_card!(customer, card_id:, provider_data:)
    payment = Payment.create!(
      order_id: new_order!(customer).id, tenant_id: @tenant.id, amount: 100,
      method: :card, provider: "tbank", status: :succeeded,
      provider_payment_id: "pay-ledger-#{SecureRandom.hex(4)}", provider_data: provider_data
    )
    Payments::SavedCardStore.persist_from_tbank!(
      payment: payment,
      payload: {
        "Status" => "CONFIRMED", "RebillId" => "rebill-#{SecureRandom.hex(3)}",
        "Pan" => "430000******1111", "ExpDate" => "1230", "CardType" => "MIR", "CardId" => card_id
      }
    )
  end

  def sbp_payment!(customer, provider_data:)
    Payment.create!(
      order_id: new_order!(customer).id, tenant_id: @tenant.id, amount: 100,
      method: :sbp, provider: "tbank", status: :pending,
      provider_payment_id: "pay-ledger-sbp-#{SecureRandom.hex(4)}", provider_data: provider_data
    )
  end
end
