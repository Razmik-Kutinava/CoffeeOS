# frozen_string_literal: true

require "test_helper"

# Связь витрина → табло бариста: оплаченный заказ /shop (callback Т-Банка) появляется
# на /barista той же точки и в live-трансляции; бариста другой точки его не видит.
class ShopOrderToBaristaBoardTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!(name: "Витрина A", slug: "shop-board-a-#{SecureRandom.hex(3)}")
    @barista = create_user!(tenant: @tenant, role_codes: %w[barista], email: "shop-board-a-#{SecureRandom.hex(3)}@test.local")
    @shift = open_cash_shift!(tenant: @tenant, opened_by: @barista)

    @order = Order.create!(
      tenant: @tenant,
      order_number: "SHOP-#{SecureRandom.hex(3).upcase}",
      source: "mobile",
      status: "pending_payment",
      total_amount: 500,
      discount_amount: 0,
      final_amount: 500
    )
    @provider_payment_id = "pay_#{SecureRandom.hex(4)}"
    Payment.create!(
      order: @order, tenant: @tenant, amount: 500, method: "card",
      provider: "tbank", provider_payment_id: @provider_payment_id, status: "pending"
    )
    ENV["TBANK_TERMINAL_KEY"] = "TestTerminal"
    ENV["TBANK_PASSWORD"] = "TestPassword"
  end

  teardown do
    ENV.delete("TBANK_TERMINAL_KEY")
    ENV.delete("TBANK_PASSWORD")
  end

  test "unpaid shop order is not on the barista board" do
    login_as!(@barista)
    get "/barista"

    assert_response :success
    refute_includes response.body, @order.order_number
  end

  test "paid shop order lands on the barista board of the same point and is broadcast live" do
    broadcasts = capture_board_broadcasts { Payments::TbankCallbackJob.perform_now(confirmed_payload) }

    assert_equal "accepted", @order.reload.status

    slots = broadcasts.find { |b| b[:target] == Barista::OrderBoardBroadcaster::BOARD_TARGET }
    assert slots, "callback must push the board over Turbo Streams"
    assert_equal "orders_#{@tenant.id}", slots[:stream]
    assert_includes slots[:locals][:orders].map(&:id), @order.id

    login_as!(@barista)
    get "/barista"
    assert_response :success
    assert_includes response.body, @order.order_number
    assert_includes response.body, %(turbo-cable-stream-source)
  end

  test "barista of another point never sees the shop order" do
    other_tenant = create_tenant!(name: "Дубль A", slug: "shop-board-dup-#{SecureRandom.hex(3)}")
    other_barista = create_user!(tenant: other_tenant, role_codes: %w[barista], email: "shop-board-dup-#{SecureRandom.hex(3)}@test.local")
    open_cash_shift!(tenant: other_tenant, opened_by: other_barista)

    Payments::TbankCallbackJob.perform_now(confirmed_payload)
    assert_equal "accepted", @order.reload.status

    login_as!(other_barista)
    get "/barista"
    assert_response :success
    refute_includes response.body, @order.order_number
  end

  private

  def confirmed_payload
    payload = {
      "TerminalKey" => "TestTerminal",
      "OrderId" => @order.id.to_s,
      "PaymentId" => @provider_payment_id,
      "Status" => "CONFIRMED",
      "Amount" => 50_000
    }
    payload["Token"] = Payments::TbankAdapter.new.build_token(payload)
    payload
  end

  def capture_board_broadcasts
    calls = []
    original = Turbo::StreamsChannel.method(:broadcast_replace_to)
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) do |stream, **kwargs|
      calls << { stream: stream, **kwargs }
    end
    yield
    calls
  ensure
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to, original)
  end
end
