# frozen_string_literal: true

require "test_helper"

class Payments::BindingVelocityTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @phone = "+7900#{format('%07d', rand(10_000_000))}"
  end

  teardown { Current.reset }

  test "allows first attempts" do
    result = Payments::BindingVelocity.check!(
      method_type: "card",
      method_hash: "hash-v1",
      phone: @phone,
      bin: "220220"
    )
    assert result.allowed?
  end

  test "rate limits by method_hash after limit" do
    Payments::BindingVelocity::LIMIT_METHOD_HASH.times do
      CardBindingAttempt.record!(
        method_type: "card",
        method_hash: "hash-limit",
        phone: @phone,
        result: "ok",
        point_id: @tenant.id
      )
    end

    result = Payments::BindingVelocity.check!(
      method_type: "card",
      method_hash: "hash-limit",
      phone: "+79001112233"
    )
    refute result.allowed?
    assert_equal "rate_limited", result.reason
  end

  test "BIN limit does not apply to sbp" do
    Payments::BindingVelocity::LIMIT_BIN.times do |i|
      CardBindingAttempt.record!(
        method_type: "card",
        method_hash: "bin-hash-#{i}-#{SecureRandom.hex(2)}",
        phone: "+7901#{format('%07d', i)}",
        bin: "427638",
        result: "ok",
        point_id: @tenant.id
      )
    end

    result = Payments::BindingVelocity.check!(
      method_type: "sbp",
      method_hash: "sbp-hash-ok",
      phone: "+79009998877",
      bin: "427638"
    )
    assert result.allowed?
  end
end
