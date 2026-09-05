# frozen_string_literal: true

module Subscriptions
  # User-initiated покупка подписки через Payments::TbankAdapter (Init→Charge по RebillId).
  # Не использует Shop::RecurrentOrderCreator. Техзаказ после оплаты → closed (не табло баристы).
  class PurchaseService
    class Error < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(customer:, plan:, purchase_point:, payment_method:, return_base_url:, notification_url:,
                   auto_renew: true, adapter: nil)
      @customer = customer
      @plan = plan
      @purchase_point = purchase_point
      @payment_method = payment_method
      @return_base_url = return_base_url
      @notification_url = notification_url
      @auto_renew = auto_renew
      @adapter = adapter || Payments::TbankAdapter.new
    end

    def call
      validate!

      order = create_technical_order!
      payment = create_payment!(order)

      init_result = @adapter.init_payment(
        order: order,
        return_base_url: @return_base_url,
        notification_url: @notification_url,
        customer_key: @customer.id.to_s,
        recurrent: false,
        receipt: build_receipt(order)
      )
      pid = init_result[:provider_payment_id].to_s
      raise Error, "Init without PaymentId" if pid.blank?

      payment.update_columns(
        provider: "tbank",
        provider_payment_id: pid,
        provider_data: (payment.provider_data || {}).merge(subscription_provider_data)
      )

      charge_response = @adapter.charge(payment_id: pid, rebill_id: @payment_method.rebill_id)
      result = Payments::TbankPaymentResult.new(charge_response)
      unless result.success?
        payment.update_columns(provider_payment_id: nil)
        raise Error, "Charge failed: #{result.error_code} #{result.message}".strip
      end

      unless result.confirmed?
        raise Error, "Charge not CONFIRMED (status=#{result.status}); 3DS/pending handled in later slice"
      end

      subscription = activate!(order: order, payment: payment, charge_response: charge_response, pid: pid)

      {
        subscription_id: subscription.id,
        order_id: order.id,
        provider_payment_id: pid,
        payment_url: init_result[:payment_url]
      }
    end

    private

    def validate!
      raise Error, "plan inactive" unless @plan.active?
      raise Error, "payment method missing rebill" if @payment_method.rebill_id.blank?
      raise Error, "payment method customer mismatch" unless @payment_method.customer_id == @customer.id
    end

    def create_technical_order!
      amount = BigDecimal(@plan.price.to_s)
      Order.create!(
        tenant_id: @purchase_point.id,
        customer_id: @customer.id,
        customer_name: @customer.full_name.presence || "Subscription",
        order_number: "",
        source: :mobile,
        status: :pending_payment,
        total_amount: amount,
        discount_amount: 0,
        final_amount: amount
      )
    end

    def create_payment!(order)
      Payment.create!(
        tenant_id: @purchase_point.id,
        order_id: order.id,
        amount: order.final_amount,
        method: :card,
        status: :pending,
        provider: "pending",
        provider_data: subscription_provider_data
      )
    end

    def subscription_provider_data
      {
        "subscription_intent" => true,
        "subscription_plan_id" => @plan.id,
        "subscription_payment_method_id" => @payment_method.id,
        "auto_renew" => @auto_renew,
        # Webhook SavedCardStore defaults save_card=true when absent — never for subscription.
        "save_card" => false
      }
    end

    def build_receipt(order)
      amount_kopecks = (BigDecimal(order.final_amount.to_s) * 100).to_i
      receipt = {
        "Taxation" => ENV.fetch("TBANK_TAXATION", "usn_income"),
        "Items" => [
          {
            "Name" => truncate_name("Подписка #{@plan.code}"),
            "Price" => amount_kopecks,
            "Quantity" => 1.0,
            "Amount" => amount_kopecks,
            "Tax" => ENV.fetch("TBANK_TAX", "none"),
            "PaymentMethod" => "full_payment",
            "PaymentObject" => "service"
          }
        ]
      }
      apply_contact!(receipt)
      receipt
    end

    def apply_contact!(receipt)
      email = @customer.email.to_s.strip
      phone = @customer.phone.to_s.strip
      if email.present? && email.match?(/\A[^\s@]+@[^\s@]+\.[^\s@]+\z/)
        receipt["Email"] = email
      elsif phone.present?
        receipt["Phone"] = phone
      end
    end

    def truncate_name(name)
      name.to_s.truncate(128, omission: "")
    end

    def activate!(order:, payment:, charge_response:, pid:)
      ActiveRecord::Base.transaction do
        payment.update!(
          status: :succeeded,
          paid_at: Time.current,
          provider: "tbank",
          provider_payment_id: pid,
          provider_data: (payment.provider_data || {}).merge(
            subscription_provider_data
          ).merge(charge_response.except("Token", "Password"))
        )
        # Не PaymentStatusUpdater → accepted (иначе попадёт на табло баристы).
        order.update!(status: :closed)
        Subscriptions::PaymentFulfillment.call(payment: payment.reload)
      end
    end
  end
end
