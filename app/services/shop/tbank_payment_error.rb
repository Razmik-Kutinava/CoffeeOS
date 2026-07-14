# frozen_string_literal: true

module Shop
  # Ошибка оплаты с ErrorCode Т-Банка.
  class TbankPaymentError < OrderCreator::Error
    attr_reader :error_code, :tbank_status

    FRIENDLY_MESSAGES = {
      "1051" => "Недостаточно средств на карте",
      "1014" => "Карта просрочена"
    }.freeze

    def self.from_api(error_code:, message:, tbank_status: nil)
      code = error_code.to_s
      friendly = FRIENDLY_MESSAGES[code]
      text = friendly || message.presence || "Ошибка оплаты"
      new(text, error_code: code, tbank_status: tbank_status)
    end

    def initialize(message, error_code:, tbank_status: nil)
      @error_code = error_code.to_s
      @tbank_status = tbank_status.to_s.presence
      super(message)
    end
  end
end
