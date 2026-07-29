# frozen_string_literal: true

module Shop
  module Api
    class PhoneOtpController < Shop::Api::BaseController
      def send_code
        phone = Shop::PhoneOtp.send_code!(
          phone: params.require(:phone),
          channel: params.require(:channel),
          ip: request.remote_ip
        )
        render json: { ok: true, phone: phone, channel: params[:channel].to_s }
      rescue Shop::PhoneOtp::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Shop::SmsRuClient::Error => e
        render json: { error: e.message }, status: :bad_gateway
      end

      def verify
        phone = Shop::PhoneOtp.verify!(
          phone: params.require(:phone),
          code: params.require(:code)
        )
        customer_id = Shop::PhoneVerifiedCustomerLinker.link!(
          session: session,
          tenant_id: @shop_tenant.id,
          phone: phone
        )
        payload = { verified: true, phone: phone }
        if customer_id.present?
          payload[:refresh_token] = Shop::MobileSessionIssuer.call!(customer_id: customer_id)
        end
        render json: payload
      rescue Shop::PhoneOtp::Error, Shop::PhoneVerifiedCustomerLinker::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::ActiveRecordError => e
        Rails.logger.error("[Shop::PhoneOtp] verify failed: #{e.class}: #{e.message}")
        render json: { error: "Не удалось сохранить подтверждение телефона. Попробуйте ещё раз." },
          status: :internal_server_error
      end

      def status
        phone_param = params[:phone].to_s
        if phone_param.blank?
          return render json: { verified: false, phone: nil }
        end

        begin
          normalized = Shop::PhoneNormalizer.normalize!(phone_param)
        rescue Shop::PhoneNormalizer::Error
          return render json: { verified: false, phone: nil }
        end

        session_cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        customer = session_cid.present? ? MobileCustomer.find_by(id: session_cid) : nil
        verified = customer.present? && customer.phone == normalized

        if !verified && customer.nil?
          by_phone = MobileCustomer.find_by(phone: normalized)
          if by_phone
            Shop::CustomerSession.set_customer_id!(session, @shop_tenant.id, by_phone.id)
            verified = true
          end
        end

        render json: { verified: verified, phone: verified ? normalized : nil }
      end
    end
  end
end
