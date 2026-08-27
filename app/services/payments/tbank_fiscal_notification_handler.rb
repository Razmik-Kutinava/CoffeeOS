# frozen_string_literal: true

module Payments
  # Inbound NotificationFiscalization (Status=RECEIPT) → FiscalReceipt.
  # Schema: docs/operations/milestones/veha_2/artifacts/fiscal_receipts_personal_cabinet/SCHEMA.md
  class TbankFiscalNotificationHandler
    REFUND_TYPES = %w[incomereturn income_return return refund возврат].freeze

    def initialize(payload:)
      @payload = payload.stringify_keys
    end

    def call!
      payment = find_payment
      unless payment
        Rails.logger.warn(
          "[TbankFiscal] Payment not found OrderId=#{@payload['OrderId']} PaymentId=#{@payload['PaymentId']}"
        )
        return { ok: true, skipped: :payment_not_found }
      end

      external_id = ofd_receipt_id
      if external_id.blank?
        Rails.logger.warn("[TbankFiscal] Missing fiscal ids PaymentId=#{@payload['PaymentId']}")
        return { ok: true, skipped: :missing_fiscal_ids }
      end

      existing = FiscalReceipt.find_by(ofd_receipt_id: external_id)
      return { ok: true, duplicate: true, fiscal_receipt: existing } if existing

      receipt = FiscalReceipt.create!(
        tenant_id: payment.tenant_id,
        order_id: payment.order_id,
        payment_id: payment.id,
        type: map_operation_type,
        status: "confirmed",
        ofd_provider: "tbank",
        ofd_receipt_id: external_id,
        confirmed_at: Time.current,
        receipt_data: stored_receipt_data
      )

      { ok: true, fiscal_receipt: receipt }
    rescue ActiveRecord::RecordNotUnique
      existing = FiscalReceipt.find_by(ofd_receipt_id: external_id)
      { ok: true, duplicate: true, fiscal_receipt: existing }
    end

    private

    def find_payment
      order_id = @payload["OrderId"].to_s
      payment_id = @payload["PaymentId"].to_s
      return nil if order_id.blank? || payment_id.blank?

      Payment
        .joins(:order)
        .where(orders: { id: order_id })
        .where(provider_payment_id: payment_id)
        .first ||
        Payment
          .joins(:order)
          .where(orders: { id: order_id }, provider: "tbank", status: :pending)
          .where(provider_payment_id: [ nil, "" ])
          .order(created_at: :desc)
          .first
    end

    def ofd_receipt_id
      payment_id = @payload["PaymentId"].to_s
      fn = @payload["FnNumber"].to_s
      fd = @payload["FiscalDocumentNumber"].to_s
      fp = @payload["FiscalDocumentAttribute"].to_s
      return nil if payment_id.blank? || (fn.blank? && fd.blank? && fp.blank?)

      "#{payment_id}:#{fn}:#{fd}:#{fp}"
    end

    def map_operation_type
      raw = @payload["Type"].to_s.strip.downcase
      return "refund" if REFUND_TYPES.include?(raw)

      "payment"
    end

    def stored_receipt_data
      {
        "Url" => @payload["Url"].to_s.presence,
        "FnNumber" => @payload["FnNumber"].to_s.presence,
        "FiscalDocumentNumber" => @payload["FiscalDocumentNumber"],
        "FiscalDocumentAttribute" => @payload["FiscalDocumentAttribute"],
        "Type" => @payload["Type"].to_s.presence,
        "Ofd" => @payload["Ofd"].to_s.presence,
        "QrCodeUrl" => @payload["QrCodeUrl"].to_s.presence,
        "ReceiptDatetime" => @payload["ReceiptDatetime"].to_s.presence,
        "FiscalNumber" => @payload["FiscalNumber"],
        "ShiftNumber" => @payload["ShiftNumber"],
        "raw" => @payload.except("Token", "Password")
      }.compact
    end
  end
end
