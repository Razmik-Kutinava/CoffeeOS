# frozen_string_literal: true

require "test_helper"

# Шаг 2 ТЗ: GET payments/status → GetState → если AUTHORIZED — auto Confirm → CONFIRMED
class Shop::Api::PaymentStatusConfirmTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    Current.tenant_id = @tenant.id
    @confirm_flag = { called: false }

    # Стабилизируем ответы Т-Банка на будущее GREEN: AUTHORIZED → Confirm → CONFIRMED
    @orig_get_state = Payments::TbankAdapter.instance_method(:get_payment_state)
    @had_confirm_before = Payments::TbankAdapter.instance_methods(false).include?(:confirm_payment)
    @orig_confirm = Payments::TbankAdapter.instance_method(:confirm_payment) if @had_confirm_before

    get_state_response = {
      "Success" => true,
      "ErrorCode" => "0",
      "Status" => "AUTHORIZED",
      "PaymentId" => "pay-auth-1"
    }

    Payments::TbankAdapter.define_method(:get_payment_state) do |payment_id:|
      # Тестовой идентичности достаточно; логика выбора payment_id будет реализована в GREEN
      get_state_response.merge("PaymentId" => payment_id.to_s)
    end

    confirm_response = {
      "Success" => true,
      "ErrorCode" => "0",
      "Status" => "CONFIRMED",
      "PaymentId" => "pay-auth-1"
    }

    confirm_flag = @confirm_flag
    Payments::TbankAdapter.define_method(:confirm_payment) do |payment_id:|
      confirm_flag[:called] = true
      confirm_response.merge("PaymentId" => payment_id.to_s)
    end
  end

  teardown do
    # Восстанавливаем переопределённые методы, чтобы не влиять на другие тесты
    Payments::TbankAdapter.define_method(:get_payment_state, @orig_get_state)
    if @had_confirm_before
      Payments::TbankAdapter.define_method(:confirm_payment, @orig_confirm)
    else
      Payments::TbankAdapter.send(:remove_method, :confirm_payment) if Payments::TbankAdapter.instance_methods(false).include?(:confirm_payment)
    end

    Current.reset
  end

  def shop_headers
    { "X-Shop-Tenant" => @tenant.id.to_s }
  end

  test "GET payments/status triggers GetState+Confirm for AUTHORIZED and returns CONFIRMED [TDD]" do
    order = Order.create!(
      tenant_id: @tenant.id,
      customer_name: "Status Confirm Guest",
      order_number: "",
      source: :mobile,
      status: :pending_payment,
      total_amount: 200,
      discount_amount: 0,
      final_amount: 200
    )

    Payment.create!(
      order_id: order.id,
      tenant_id: @tenant.id,
      amount: 200,
      method: :sbp,
      provider: "tbank",
      status: :processing,
      provider_payment_id: "pay-auth-1"
    )

    get "/shop/api/payments/status/#{order.id}", headers: shop_headers, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "CONFIRMED", body["status"]
    assert @confirm_flag[:called], "ожидали auto Confirm при AUTHORIZED"
  end
end

