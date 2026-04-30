# frozen_string_literal: true

require "test_helper"

class ProductTenantSettingTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant   = create_tenant!
    category  = create_category!
    @product  = create_product!(category: category)
  end

  def build_setting(overrides = {})
    ProductTenantSetting.new(
      {
        tenant:        @tenant,
        product:       @product,
        price:         100,
        is_enabled:    false,
        is_sold_out:   false
      }.merge(overrides)
    )
  end

  # ---------------------------------------------------------------------------
  # enabled_requires_price
  # ---------------------------------------------------------------------------

  test "is_enabled true with nil price is invalid" do
    setting = build_setting(is_enabled: true, price: nil)
    assert_not setting.valid?
    assert setting.errors[:price].any?
  end

  test "is_enabled true with price set is valid" do
    setting = build_setting(is_enabled: true, price: 100)
    assert setting.valid?
  end

  test "is_enabled false with nil price is valid" do
    setting = build_setting(is_enabled: false, price: nil)
    assert setting.valid?
  end

  # ---------------------------------------------------------------------------
  # sold_out_reason_consistency
  # ---------------------------------------------------------------------------

  test "is_sold_out true with nil sold_out_reason is invalid" do
    setting = build_setting(is_sold_out: true, sold_out_reason: nil)
    assert_not setting.valid?
    assert setting.errors[:sold_out_reason].any?
  end

  test "is_sold_out true with sold_out_reason manual is valid" do
    setting = build_setting(is_sold_out: true, sold_out_reason: "manual")
    assert setting.valid?
  end

  test "is_sold_out true with sold_out_reason stock_empty is valid" do
    setting = build_setting(is_sold_out: true, sold_out_reason: "stock_empty")
    assert setting.valid?
  end

  test "is_sold_out true with invalid sold_out_reason other is invalid" do
    setting = build_setting(is_sold_out: true, sold_out_reason: "other")
    assert_not setting.valid?
    assert setting.errors[:sold_out_reason].any?
  end

  test "is_sold_out false with nil sold_out_reason is valid" do
    setting = build_setting(is_sold_out: false, sold_out_reason: nil)
    assert setting.valid?
  end

  test "is_sold_out false with a reason set is invalid due to inconsistency" do
    setting = build_setting(is_sold_out: false, sold_out_reason: "manual")
    assert_not setting.valid?
    assert setting.errors[:sold_out_reason].any?
  end

  # ---------------------------------------------------------------------------
  # Uniqueness constraint
  # ---------------------------------------------------------------------------

  test "duplicate product + tenant combination is invalid" do
    # Persist the first setting
    build_setting(is_enabled: false, price: nil).save!

    duplicate = build_setting(is_enabled: false, price: nil)
    assert_not duplicate.valid?
    assert duplicate.errors[:tenant_id].any?
  end

  # ---------------------------------------------------------------------------
  # available?
  # ---------------------------------------------------------------------------

  test "available? returns true when is_enabled true, not sold_out and price present" do
    setting = build_setting(is_enabled: true, price: 100, is_sold_out: false)
    assert setting.available?
  end

  test "available? returns false when product is disabled" do
    setting = build_setting(is_enabled: false, price: 100, is_sold_out: false)
    assert_not setting.available?
  end

  test "available? returns false when product is sold out" do
    setting = build_setting(is_enabled: true, price: 100, is_sold_out: true, sold_out_reason: "manual")
    assert_not setting.available?
  end

  test "available? returns false when price is nil" do
    # is_enabled false so the enabled_requires_price validation doesn't fire
    setting = build_setting(is_enabled: false, price: nil)
    assert_not setting.available?
  end

  # ---------------------------------------------------------------------------
  # price numericality
  # ---------------------------------------------------------------------------

  test "price must be greater than 0" do
    setting = build_setting(is_enabled: true, price: 0)
    assert_not setting.valid?
    assert setting.errors[:price].any?
  end

  test "negative price is invalid" do
    setting = build_setting(is_enabled: true, price: -10)
    assert_not setting.valid?
    assert setting.errors[:price].any?
  end
end
