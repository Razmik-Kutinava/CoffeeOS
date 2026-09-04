# frozen_string_literal: true

module Payments
  # #34 Шаг 2: после CONFIRMED + RequestKey → GetAddAccountQRState → SbpAccountTokenStore.
  class SbpAccountTokenFromWebhook
    def initialize(autopay: nil)
      @autopay = autopay || TbankSbpAutopay.new
    end

    def call!(payment:, payload:)
      data = payload.stringify_keys
      return unless data["Status"].to_s.upcase == "CONFIRMED"
      return unless save_sbp_account?(payment)

      request_key = data["RequestKey"].to_s.presence
      return if request_key.blank?

      customer_id = payment.order&.customer_id
      return if customer_id.blank?

      result = @autopay.get_add_account_qr_state(request_key: request_key)
      stored = SbpAccountTokenStore.persist!(
        customer_id: customer_id,
        account_token: result[:account_token],
        request_key: request_key
      )
      return if stored == SbpAccountTokenStore::BLOCKED

      stored
    end

    private

    def save_sbp_account?(payment)
      raw = payment&.provider_data
      raw = {} unless raw.is_a?(Hash)
      ActiveModel::Type::Boolean.new.cast(raw["save_sbp_account"])
    end
  end
end
