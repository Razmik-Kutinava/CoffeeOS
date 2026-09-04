# frozen_string_literal: true

module Shop
  module Api
    class PhoneOtpController < Shop::Api::BaseController
      def init_callcheck
        result = Shop::PhoneOtp.init_callcheck!(
          phone: params.require(:phone),
          session: session,
          tenant_id: @shop_tenant.id
        )
        render json: {
          ok: true,
          phone: result[:phone],
          check_id: result[:check_id],
          call_phone: result[:call_phone],
          call_phone_pretty: result[:call_phone_pretty],
          call_phone_html: result[:call_phone_html]
        }
      rescue Shop::PhoneOtp::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Shop::SmsRuClient::Error => e
        render json: { error: e.message }, status: :bad_gateway
      end

      def check_status
        result = Shop::PhoneOtp.poll_callcheck!(
          session: session,
          tenant_id: @shop_tenant.id
        )

        unless result[:confirmed]
          return render json: {
            confirmed: false,
            phone: result[:phone],
            check_status: result[:check_status],
            expired: result[:expired] == true
          }
        end

        phone = result[:phone]
        customer_id = Shop::PhoneVerifiedCustomerLinker.link!(
          session: session,
          tenant_id: @shop_tenant.id,
          phone: phone
        )
        payload = { confirmed: true, verified: true, phone: phone }
        if customer_id.present?
          payload[:refresh_token] = Shop::MobileSessionIssuer.call!(customer_id: customer_id)
        end
        render json: payload
      rescue Shop::PhoneOtp::Error, Shop::PhoneVerifiedCustomerLinker::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Shop::SmsRuClient::Error => e
        render json: { error: e.message }, status: :bad_gateway
      rescue ActiveRecord::ActiveRecordError => e
        Rails.logger.error("[Shop::PhoneOtp] callcheck complete failed: #{e.class}: #{e.message}")
        render json: { error: "Не удалось сохранить подтверждение телефона. Попробуйте ещё раз." },
          status: :internal_server_error
      end

      def send_sms
        if ActiveModel::Type::Boolean.new.cast(params[:binding_step_up])
          cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
          customer = MobileCustomer.find_by(id: cid)
          phone_param = Payments::BindingStepUp.resolve_otp_destination(
            customer: customer,
            form_phone: params[:phone]
          )
          raise Shop::PhoneOtp::Error, "Нет телефона аккаунта для подтверждения" if phone_param.blank?
        else
          phone_param = params.require(:phone)
        end

        phone = Shop::PhoneOtp.send_sms_code!(
          phone: phone_param,
          ip: request.remote_ip
        )
        render json: { ok: true, phone: phone, channel: "sms" }
      rescue Shop::PhoneOtp::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Shop::SmsRuClient::Error => e
        render json: { error: e.message }, status: :bad_gateway
      end

      def verify_sms
        phone = Shop::PhoneOtp.verify_sms!(
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
        Rails.logger.error("[Shop::PhoneOtp] verify_sms failed: #{e.class}: #{e.message}")
        render json: { error: "Не удалось сохранить подтверждение телефона. Попробуйте ещё раз." },
          status: :internal_server_error
      end

      # Legacy: Profile link — SMS only (flash_call removed from auth).
      def send_code
        channel = params.require(:channel).to_s
        raise Shop::PhoneOtp::Error, "Выберите SMS" unless channel == "sms"

        phone = Shop::PhoneOtp.send_sms_code!(
          phone: params.require(:phone),
          ip: request.remote_ip
        )
        render json: { ok: true, phone: phone, channel: "sms" }
      rescue Shop::PhoneOtp::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Shop::SmsRuClient::Error => e
        render json: { error: e.message }, status: :bad_gateway
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def verify
        verify_sms
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

        render json: { verified: verified, phone: verified ? normalized : nil }
      end
    end
  end
end
