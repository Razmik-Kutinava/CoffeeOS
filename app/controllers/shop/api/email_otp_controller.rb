# frozen_string_literal: true

module Shop
  module Api
    class EmailOtpController < Shop::Api::BaseController
      def send_code
        email = Shop::EmailOtp.send_code!(email: params.require(:email))
        render json: { ok: true, email: email }
      rescue Shop::EmailOtp::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def verify
        email = Shop::EmailOtp.verify!(email: params.require(:email), code: params.require(:code))
        Shop::EmailVerification.mark_verified!(
          session: session,
          tenant_id: @shop_tenant.id,
          email: email,
          session_id: request.session.id
        )
        Shop::EmailVerifiedCustomerLinker.link!(
          session: session,
          tenant_id: @shop_tenant.id,
          email: email
        )
        render json: { verified: true, email: email }
      rescue Shop::EmailOtp::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::ActiveRecordError => e
        Rails.logger.error("[Shop::EmailOtp] mark_verified failed: #{e.class}: #{e.message}")
        render json: { error: "Не удалось сохранить подтверждение email. Попробуйте ещё раз." },
          status: :internal_server_error
      end

      def status
        email = Shop::EmailVerification.verified_email(
          session: session,
          tenant_id: @shop_tenant.id,
          session_id: request.session.id,
          email: params[:email]
        )
        # F5 / новая cookie: verification в БД есть — вернуть customer_id в сессию без нового OTP
        if email.present?
          Shop::EmailVerifiedCustomerLinker.link!(
            session: session,
            tenant_id: @shop_tenant.id,
            email: email
          )
        end
        render json: { verified: email.present?, email: email }
      end
    end
  end
end
