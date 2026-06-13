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
        render json: { verified: true, email: email }
      rescue Shop::EmailOtp::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def status
        email = Shop::EmailVerification.verified_email(
          session: session,
          tenant_id: @shop_tenant.id,
          session_id: request.session.id,
          email: params[:email]
        )
        render json: { verified: email.present?, email: email }
      end
    end
  end
end
