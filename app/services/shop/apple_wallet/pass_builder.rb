# frozen_string_literal: true

module Shop
  module AppleWallet
    # Сборка .pkpass (simulate stub; prod — PKCS7). #38 — face / back / strip.
    class PassBuilder
      # B1.1 orderStatusProgress: fillPercent = activeIndex / 3 * 100
      FILL_PERCENT = {
        "accepted" => (1.0 / 3 * 100),
        "preparing" => (2.0 / 3 * 100),
        "ready" => 100.0
      }.freeze

      FACE_STATUS_TEXT = {
        "accepted" => "Заказ оплачен",
        "preparing" => "Заказ готовится",
        "ready" => "Заказ готов"
      }.freeze

      def self.build!(order:, status_label:, serial_number:, authentication_token:)
        new(
          order: order,
          status_label: status_label,
          serial_number: serial_number,
          authentication_token: authentication_token
        ).build!
      end

      def initialize(order:, status_label:, serial_number:, authentication_token:)
        @order = order
        @status_label = status_label.to_s
        @serial_number = serial_number
        @authentication_token = authentication_token
      end

      def build!
        raise GenerationError, "forced generation error" if Config.force_gen_error?
        raise UnavailableError, "wallet unavailable" unless Config.available?

        if Config.simulate? || !Config.certs_configured?
          return simulate_payload
        end

        raise GenerationError, "WALLET signer configured but PassKit signing not implemented yet"
      end

      private

      def simulate_payload
        {
          simulated: true,
          serial_number: @serial_number,
          authentication_token: @authentication_token,
          status_label: @status_label,
          face: face_fields,
          back: back_fields,
          strip: strip_fields,
          bytes: "PKPASS_STUB:#{@order.id}:#{@status_label}"
        }
      end

      def face_fields
        if @status_label == "ready"
          number = @order.order_number.presence || @order.id.to_s
          return {
            kind: "qr",
            text: FACE_STATUS_TEXT["ready"],
            qr_payload: "CoffeeOS order #{number}"
          }
        end

        {
          kind: "status",
          text: FACE_STATUS_TEXT[@status_label].presence || @status_label
        }
      end

      def back_fields
        {
          chat_url: "/shop/#/order/#{@order.id}?action=chat",
          tips_url: "/shop/#/order/#{@order.id}?action=tips"
        }
      end

      def strip_fields
        progress = Shop::OrderStatusPushPayload::PROGRESS[@status_label]
        {
          progress: progress,
          fill_percent: FILL_PERCENT[@status_label],
          source: "order_status_progress"
        }
      end
    end
  end
end
