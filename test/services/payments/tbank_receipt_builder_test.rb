# frozen_string_literal: true

require "test_helper"

# GREEN [TDD] Шаг 1: Receipt 54-ФЗ для Init Т-Кассы.
class Payments::TbankReceiptBuilderTest < ActiveSupport::TestCase
  ItemStub = Struct.new(:product_name, :unit_price, :quantity, :total_price, keyword_init: true)
  OrderStub = Struct.new(:id, :final_amount, :order_items, keyword_init: true)

  setup do
    ENV["TBANK_TAXATION"] = "usn_income"
    ENV["TBANK_TAX"] = "none"
  end

  teardown do
    ENV.delete("TBANK_TAXATION")
    ENV.delete("TBANK_TAX")
  end

  test "call! builds Receipt with Taxation and Items from order" do
    order = OrderStub.new(
      id: SecureRandom.uuid,
      final_amount: BigDecimal("350.00"),
      order_items: [
        ItemStub.new(
          product_name: "Латте",
          unit_price: BigDecimal("175.00"),
          quantity: 2,
          total_price: BigDecimal("350.00")
        )
      ]
    )

    receipt = Payments::TbankReceiptBuilder.call!(
      order: order,
      email: "guest@example.com"
    )

    assert_equal "usn_income", receipt["Taxation"]
    assert_equal "guest@example.com", receipt["Email"]
    assert_equal 1, receipt["Items"].size

    item = receipt["Items"].first
    assert_equal "Латте", item["Name"]
    assert_equal 17_500, item["Price"]
    assert_equal 2.0, item["Quantity"]
    assert_equal 35_000, item["Amount"]
    assert_equal "none", item["Tax"]
    assert_equal "full_payment", item["PaymentMethod"]
    assert_equal "commodity", item["PaymentObject"]
  end

  test "call! preserves special characters in product Name for 54-FZ" do
    order = OrderStub.new(
      id: SecureRandom.uuid,
      final_amount: BigDecimal("100.00"),
      order_items: [
        ItemStub.new(
          product_name: 'Какао "Горький" 70% & ещё',
          unit_price: BigDecimal("100.00"),
          quantity: 1,
          total_price: BigDecimal("100.00")
        )
      ]
    )

    receipt = Payments::TbankReceiptBuilder.call!(order: order)
    assert_equal 'Какао "Горький" 70% & ещё', receipt["Items"].first["Name"]
  end

  test "call! raises on empty order items" do
    order = OrderStub.new(
      id: SecureRandom.uuid,
      final_amount: BigDecimal("0"),
      order_items: []
    )

    assert_raises(Payments::TbankReceiptBuilder::Error) do
      Payments::TbankReceiptBuilder.call!(order: order)
    end
  end

  test "call! uses TBANK_TAXATION and TBANK_TAX from env" do
    ENV["TBANK_TAXATION"] = "osn"
    ENV["TBANK_TAX"] = "vat20"

    order = OrderStub.new(
      id: SecureRandom.uuid,
      final_amount: BigDecimal("100.00"),
      order_items: [
        ItemStub.new(
          product_name: "Эспрессо",
          unit_price: BigDecimal("100.00"),
          quantity: 1,
          total_price: BigDecimal("100.00")
        )
      ]
    )

    receipt = Payments::TbankReceiptBuilder.call!(order: order)
    assert_equal "osn", receipt["Taxation"]
    assert_equal "vat20", receipt["Items"].first["Tax"]
  end
end
