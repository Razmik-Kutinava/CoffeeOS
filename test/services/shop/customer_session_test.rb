# frozen_string_literal: true

require "test_helper"

class Shop::CustomerSessionTest < ActiveSupport::TestCase
  test "stores and reads customer per tenant" do
    session = {}
    Shop::CustomerSession.set_customer_id!(session, "tenant-a", "cust-a")
    Shop::CustomerSession.set_customer_id!(session, "tenant-b", "cust-b")

    assert_equal "cust-a", Shop::CustomerSession.customer_id(session, "tenant-a")
    assert_equal "cust-b", Shop::CustomerSession.customer_id(session, "tenant-b")
  end

  test "falls back to legacy shop_customer_id when bucket empty" do
    session = { shop_customer_id: "legacy-id" }
    assert_equal "legacy-id", Shop::CustomerSession.customer_id(session, "any-tenant")
  end

  test "does not use legacy customer for another tenant in bucket" do
    session = {}
    Shop::CustomerSession.set_customer_id!(session, "tenant-a", "cust-a")

    assert_nil Shop::CustomerSession.customer_id(session, "tenant-b")
    assert_equal "cust-a", Shop::CustomerSession.customer_id(session, "tenant-a")
  end
end
