# frozen_string_literal: true

require "test_helper"
require_relative "../support/rls_test_helper"

# TASK_93-G T-G2/G3/G4: must-have inventory + ensure_all! + triggers/policies present.
class PgInventoryTest < ActiveSupport::TestCase
  include RlsTestHelper

  self.use_transactional_tests = false

  MUST_HAVE_TRIGGERS = %w[
    trg_generate_order_number
    trg_auto_deduct_ingredients
    trg_auto_stop_list
  ].freeze

  MUST_HAVE_POLICY_TABLES = %w[
    orders
    order_items
    payments
    product_tenant_settings
    cash_shifts
    ingredient_tenant_stocks
    stock_movements
    devices
  ].freeze

  setup do
    DatabaseTriggers.ensure_all! if DatabaseTriggers.respond_to?(:ensure_all!)
    RlsTestBootstrap.ensure_policies!
  end

  test "T-G2a inventory file is committed" do
    path = Rails.root.join("docs/operations/dev/RLS_PG_INVENTORY.md")
    assert path.exist?, "expected #{path}"
    body = path.read
    assert_match(/trg_generate_order_number/, body)
    assert_match(/app\.shop_city_lookup/, body)
  end

  test "T-G2b must-have tables have pg_policies" do
    conn = ActiveRecord::Base.connection
    MUST_HAVE_POLICY_TABLES.each do |table|
      next unless conn.table_exists?(table)

      count = conn.select_value(
        "SELECT COUNT(*) FROM pg_policies WHERE tablename = #{conn.quote(table)}"
      ).to_i
      assert_operator count, :>, 0, "expected pg_policies on #{table}"
    end
  end

  test "T-G2c must-have triggers present in pg_trigger" do
    conn = ActiveRecord::Base.connection
    MUST_HAVE_TRIGGERS.each do |name|
      count = conn.select_value(
        "SELECT COUNT(*) FROM pg_trigger WHERE tgname = #{conn.quote(name)}"
      ).to_i
      assert_operator count, :>, 0, "expected trigger #{name}"
    end
  end

  test "T-G3a ensure_all! restores missing must-have triggers" do
    assert DatabaseTriggers.respond_to?(:ensure_all!), "DatabaseTriggers.ensure_all! required (R3-B)"

    conn = ActiveRecord::Base.connection
    conn.execute("DROP TRIGGER IF EXISTS trg_auto_deduct_ingredients ON orders")
    conn.execute("DROP TRIGGER IF EXISTS trg_auto_stop_list ON ingredient_tenant_stocks")

    DatabaseTriggers.ensure_all!

    MUST_HAVE_TRIGGERS.each do |name|
      count = conn.select_value(
        "SELECT COUNT(*) FROM pg_trigger WHERE tgname = #{conn.quote(name)}"
      ).to_i
      assert_operator count, :>, 0, "ensure_all! must restore #{name}"
    end
  end

  test "T-G4a fresh bootstrap has enough pg_policies" do
    conn = ActiveRecord::Base.connection
    count = conn.select_value("SELECT COUNT(*) FROM pg_policies").to_i
    assert_operator count, :>=, 10, "expected pg_policies >= 10 after ensure (got #{count})"
  end
end
