# frozen_string_literal: true

require "test_helper"

class CardBindingAttemptPrivacyTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
  end

  teardown { Current.reset }

  test "record! stores phone_digest not raw phone" do
    row = CardBindingAttempt.record!(
      method_type: "card",
      method_hash: "mh-1",
      phone: "+79001112233",
      account_id: SecureRandom.uuid,
      result: "ok",
      point_id: @tenant.id
    )
    assert row.phone_digest.present?
    assert_nil row.phone
    assert_equal CardBindingAttempt.phone_digest_for("+79001112233"), row.phone_digest
  end

  test "purge_expired! removes old non-growth attempts" do
    old = CardBindingAttempt.record!(
      method_type: "sbp",
      method_hash: "old-1",
      phone: "+79001112234",
      result: "ok",
      point_id: @tenant.id
    )
    old.update_columns(created_at: 100.days.ago)

    growth = CardBindingAttempt.record!(
      method_type: "card",
      method_hash: "g-1",
      phone: "+79001112235",
      result: "ok",
      is_growth_event: true,
      point_id: @tenant.id
    )

    deleted = CardBindingAttempt.purge_expired!
    assert deleted >= 1
    refute CardBindingAttempt.exists?(id: old.id)
    assert CardBindingAttempt.exists?(id: growth.id)
  end
end
