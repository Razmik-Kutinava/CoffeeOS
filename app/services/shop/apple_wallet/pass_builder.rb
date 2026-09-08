# frozen_string_literal: true

module Shop
  module AppleWallet
    # Сборка .pkpass (simulate stub; prod — PKCS7 via PassSigner). #38 — face / back / strip.
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

        signed_payload
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

      def signed_payload
        face = face_fields
        back = back_fields
        strip = strip_fields
        bytes = PassSigner.sign!(pass_json: pass_json_hash(face: face, back: back, strip: strip))

        {
          serial_number: @serial_number,
          authentication_token: @authentication_token,
          status_label: @status_label,
          face: face,
          back: back,
          strip: strip,
          bytes: bytes
        }
      end

      def pass_json_hash(face:, back:, strip:)
        payload = {
          formatVersion: 1,
          passTypeIdentifier: Config.pass_type_identifier,
          serialNumber: @serial_number.to_s,
          teamIdentifier: ENV.fetch("WALLET_TEAM_ID"),
          authenticationToken: @authentication_token.to_s,
          organizationName: "CoffeeOS",
          description: "Статус заказа CoffeeOS",
          storeCard: {
            primaryFields: [
              {
                key: "status",
                label: "Статус",
                value: face[:text].to_s
              }
            ],
            secondaryFields: [
              {
                key: "order",
                label: "Заказ",
                value: (@order.order_number.presence || @order.id).to_s
              }
            ],
            auxiliaryFields: [
              {
                key: "progress",
                label: "Прогресс",
                value: strip[:progress].to_s
              }
            ],
            backFields: [
              {
                key: "chat",
                label: "Чат",
                value: back[:chat_url].to_s
              },
              {
                key: "tips",
                label: "Чаевые",
                value: back[:tips_url].to_s
              }
            ]
          }
        }

        if face[:kind] == "qr" && face[:qr_payload].present?
          payload[:barcodes] = [
            {
              format: "PKBarcodeFormatQR",
              message: face[:qr_payload].to_s,
              messageEncoding: "iso-8859-1"
            }
          ]
        end

        payload
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
