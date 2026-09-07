# frozen_string_literal: true

require "test_helper"

class Payments::AmountLimitsTest < ActiveSupport::TestCase
  test "MIN_CHARGE_RUB is 10" do
    assert_equal 10, Payments::AmountLimits::MIN_CHARGE_RUB
    assert_equal 1000, Payments::AmountLimits::MIN_CHARGE_KOPECKS
  end

  test "below_minimum? for amounts under 10" do
    assert Payments::AmountLimits.below_minimum?(9.99)
    assert Payments::AmountLimits.below_minimum?(2)
    refute Payments::AmountLimits.below_minimum?(10)
    refute Payments::AmountLimits.below_minimum?(11)
  end

  test "ensure_chargeable! raises TooSmall under 10" do
    assert_raises(Payments::AmountLimits::TooSmall) do
      Payments::AmountLimits.ensure_chargeable!(1.79)
    end
  end
end
