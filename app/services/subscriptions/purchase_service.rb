# frozen_string_literal: true

module Subscriptions
  # User-initiated покупка подписки через Payments::TbankAdapter (Init→Charge по RebillId
  # или Init+PaymentURL без сохранённого PM — bind в том же платеже).
  # Не использует Shop::RecurrentOrderCreator. Техзаказ после оплаты → closed.
  class PurchaseService
    class Error < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(customer:, plan:, purchase_point:, return_base_url:, notification_url:,
                   payment_method: nil, payment_method_type: "card", auto_renew: true,
                   utm_campaign: nil, utm_content: nil, offer_channel: nil, adapter: nil)
      @customer = customer
      @plan = plan
      @purchase_point = purchase_point
      @payment_method = payment_method
      @payment_method_type = payment_method_type.to_s
      @return_base_url = return_base_url
      @notification_url = notification_url
      @auto_renew = auto_renew
      @utm_campaign = utm_campaign
      @utm_content = utm_content
      @offer_channel = offer_channel
      @adapter = adapter || Payments::TbankAdapter.new
    end

    def call
      validate!

      order = create_technical_order!
      payment = create_payment!(order)

      if chargeable_rebill?
        charge_and_activate!(order: order, payment: payment)
      else
        init_redirect_flow!(order: order, payment: payment)
      end
    end

    private

    def validate!
      raise Error, "plan inactive" unless @plan.active?
      if @offer_channel.present? && !Subscription::OFFER_CHANNELS.include?(@offer_channel.to_s)
        raise Error, "invalid offer_channel"
      end
      return if @payment_method.blank?

      raise Error, "payment method missing rebill" if @payment_method.rebill_id.blank?
      raise Error, "payment method customer mismatch" unless @payment_method.customer_id == @customer.id
    end

    def chargeable_rebill?
      @payment_method.present? && @payment_method.rebill_id.present?
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
      method = @payment_method_type == "sbp" ? :sbp : :card
      Payment.create!(
        tenant_id: @purchase_point.id,
        order_id: order.id,
        amount: order.final_amount,
        method: method,
        status: :pending,
        provider: "pending",
        provider_data: subscription_provider_data
      )
    end

    def subscription_provider_data
      data = {
        "subscription_intent" => true,
        "subscription_plan_id" => @plan.id,
        "auto_renew" => @auto_renew,
        "utm_campaign" => @utm_campaign,
        "utm_content" => @utm_content,
        "offer_channel" => @offer_channel
      }
      if @payment_method.present?
        data["subscription_payment_method_id"] = @payment_method.id
        # Existing rebill charge — never trigger SavedCardStore growth path.
        data["save_card"] = false
      else
        # Bind in the same payment when the flow supports it (card recurrent / SBP token).
        data["save_card"] = @payment_method_type != "sbp"
        data["save_sbp_account"] = @payment_method_type == "sbp"
      end
      data.compact
    end

    def attribution
      {
        utm_campaign: @utm_campaign,
        utm_content: @utm_content,
        offer_channel: @offer_channel
      }
    end

    def charge_and_activate!(order:, payment:)
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

    def init_redirect_flow!(order:, payment:)
      init_result = @adapter.init_payment(
        order: order,
        return_base_url: @return_base_url,
        notification_url: @notification_url,
        customer_key: @customer.id.to_s,
        recurrent: @payment_method_type != "sbp",
        receipt: build_receipt(order)
      )
      pid = init_result[:provider_payment_id].to_s
      raise Error, "Init without PaymentId" if pid.blank?

      payment.update!(
        provider: "tbank",
        provider_payment_id: pid,
        provider_data: (payment.provider_data || {}).merge(subscription_provider_data)
      )

      {
        subscription_id: nil,
        order_id: order.id,
        provider_payment_id: pid,
        payment_url: init_result[:payment_url],
        pending_payment: true
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
      if email.present? && URI::MailTo::EMAIL_REGEXP.match?(email)
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
        order.update!(status: :closed)
        Subscriptions::PaymentFulfillment.call(payment: payment.reload)
      end
    end
  end
end
