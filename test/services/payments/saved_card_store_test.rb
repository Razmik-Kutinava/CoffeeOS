# frozen_string_literal: true

require "test_helper"

# #74 [TDD] card_hash: одна активная привязка глобально, отказ без утечки.
class Payments::SavedCardStoreTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @customer_a = create_mobile_customer!(email: "card-hash-a-#{SecureRandom.hex(3)}@example.com")
    @customer_b = create_mobile_customer!(email: "card-hash-b-#{SecureRandom.hex(3)}@example.com")
  end

  teardown do
    Current.reset
  end

  test "persist sets stable card_hash from CardId and does not expose card_token to JSON" do
    card = persist!(@customer_a, card_id: "card-shared-1", rebill: "rebill-a-1", pan: "430000******1111")

    assert card.persisted?
    expected = Payments::SavedCardStore.card_hash_for("card-shared-1")
    assert expected.present?, "[TDD] card_hash_for должен давать стабильный hash"
    assert_equal expected, card.card_hash
    assert_equal expected, Payments::SavedCardStore.card_hash_for("card-shared-1")

    json = Shop::SavedCardJson.serialize(card)
    refute json.key?(:card_token)
    refute json.key?("card_token")
    refute json.key?(:card_hash)
    refute json.key?("card_hash")
  end

  test "without CardId card_hash stays nil (no global uniqueness yet)" do
    card = persist!(@customer_a, card_id: nil, rebill: "rebill-no-cardid", pan: "430000******2222")

    assert card.persisted?
    assert_nil card.card_hash
  end

  test "second account binding same CardId is controlled refusal without foreign card leak" do
    first = persist!(@customer_a, card_id: "card-shared-2", rebill: "rebill-a-2", pan: "430000******3333")
    assert first.persisted?
    assert first.card_hash.present?

    refusal = nil
    error = nil
    begin
      refusal = persist!(@customer_b, card_id: "card-shared-2", rebill: "rebill-b-2", pan: "430000******3333")
    rescue StandardError => e
      error = e
    end

    assert_nil error, "[TDD] unique conflict не должен давать 500/исключение наружу: #{error&.class}: #{error&.message}"
    assert_nil refusal, "[TDD] отказ привязки — nil (нейтральный результат)"

    assert_equal 1, MobilePaymentMethod.where(card_hash: first.card_hash, is_active: true).count
    assert_equal 0, MobilePaymentMethod.where(customer_id: @customer_b.id, payment_type: "card", is_active: true).count

    # Чужие признаки карты не должны «всплыть» в сериализации чужого primary
    assert_nil Shop::SavedCardJson.serialize(MobilePaymentMethod.primary_for(@customer_b.id))
  end

  test "same account re-bind same CardId upserts without unique failure" do
    a = persist!(@customer_a, card_id: "card-own-1", rebill: "rebill-own-1", pan: "430000******4444")
    b = persist!(@customer_a, card_id: "card-own-1", rebill: "rebill-own-1b", pan: "430000******4444")

    assert b.persisted?
    assert_equal a.id, b.id
    assert_equal "rebill-own-1b", b.card_token
    assert_equal 1, MobilePaymentMethod.where(customer_id: @customer_a.id, card_hash: a.card_hash, is_active: true).count
  end

  test "parallel bind of same card_hash: exactly one active, other controlled refusal" do
    card_id = "card-race-#{SecureRandom.hex(4)}"
    results = Array.new(2)
    errors = Array.new(2)

    threads = [
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Current.tenant_id = @tenant.id
          begin
            results[0] = persist!(@customer_a, card_id: card_id, rebill: "rebill-race-a", pan: "430000******5555")
          rescue StandardError => e
            errors[0] = e
          end
        end
      end,
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Current.tenant_id = @tenant.id
          begin
            results[1] = persist!(@customer_b, card_id: card_id, rebill: "rebill-race-b", pan: "430000******5555")
          rescue StandardError => e
            errors[1] = e
          end
        end
      end
    ]
    threads.each(&:join)

    assert errors.all?(&:nil?), "[TDD] race не должен ронять необработанным: #{errors.compact.map { |e| "#{e.class}: #{e.message}" }}"
    winners = results.compact
    assert_equal 1, winners.size, "[TDD] ровно одна успешная привязка, got=#{results.inspect}"
    hash = Payments::SavedCardStore.card_hash_for(card_id)
    assert_equal 1, MobilePaymentMethod.where(card_hash: hash, is_active: true).count
  end

  test "legacy foreign row with same bank_card_id and nil card_hash blocks second account" do
    MobilePaymentMethod.create!(
      customer_id: @customer_a.id,
      payment_type: "card",
      card_token: "rebill-legacy-a",
      card_masked: "*6666",
      card_brand: "MIR",
      card_expires_at: "12/28",
      bank_card_id: "card-legacy-1",
      card_hash: nil,
      is_active: true,
      is_default: true
    )

    refusal = persist!(@customer_b, card_id: "card-legacy-1", rebill: "rebill-legacy-b", pan: "430000******6666")
    assert_nil refusal
    assert_equal 0, MobilePaymentMethod.where(customer_id: @customer_b.id, payment_type: "card", is_active: true).count
  end

  test "pan+exp match does not rewrite row when CardId differs" do
    first = persist!(@customer_a, card_id: "card-pan-old", rebill: "rebill-pan-old", pan: "430000******7777")
    second = persist!(@customer_a, card_id: "card-pan-new", rebill: "rebill-pan-new", pan: "430000******7777")

    assert second.persisted?
    refute_equal first.id, second.id, "разный CardId при том же last4+exp — отдельная строка, не угон hash"
    assert_equal "card-pan-old", first.reload.bank_card_id
    assert_equal "card-pan-new", second.bank_card_id
  end

  test "card_hash_pepper prefers CARD_HASH_PEPPER over secret_key_base" do
    old = ENV["CARD_HASH_PEPPER"]
    ENV["CARD_HASH_PEPPER"] = "stable-pepper-for-tests"
    begin
      a = Payments::SavedCardStore.card_hash_for("card-pepper-1")
      b = OpenSSL::HMAC.hexdigest("SHA256", "stable-pepper-for-tests", "mobile_payment_methods.card_hash.v1:card-pepper-1")
      assert_equal b, a
      refute_equal OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "mobile_payment_methods.card_hash.v1:card-pepper-1"), a
    ensure
      if old
        ENV["CARD_HASH_PEPPER"] = old
      else
        ENV.delete("CARD_HASH_PEPPER")
      end
    end
  end

  private

  def persist!(customer, card_id:, rebill:, pan:)
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_id: customer.id,
      customer_name: "Hash Guest",
      order_number: "",
      source: :mobile,
      status: :accepted,
      total_amount: 100,
      discount_amount: 0,
      final_amount: 100
    )
    payment = Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 100,
      method: :card,
      provider: "tbank",
      status: :succeeded,
      provider_payment_id: "pay-hash-#{SecureRandom.hex(4)}",
      provider_data: { "save_card" => true }
    )

    payload = {
      "Status" => "CONFIRMED",
      "RebillId" => rebill,
      "Pan" => pan,
      "ExpDate" => "1228",
      "CardType" => "MIR"
    }
    payload["CardId"] = card_id if card_id.present?

    Payments::SavedCardStore.persist_from_tbank!(payment: payment, payload: payload)
  end
end
