# frozen_string_literal: true

module Shop
  module Api
    class ProfileController < Shop::Api::BaseController
      before_action :require_customer!

      def show
        render json: profile_json(@customer)
      end

      def update
        attrs = params.permit(:first_name, :last_name)
        if attrs[:first_name].to_s.strip.blank?
          return render json: { error: "Укажите имя" }, status: :unprocessable_entity
        end

        @customer.first_name = attrs[:first_name].to_s.strip
        @customer.last_name = attrs[:last_name].to_s.strip.presence
        @customer.save!
        render json: profile_json(@customer)
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end

      def link_email
        email = params.require(:email).to_s
        code = params.require(:code).to_s
        Shop::EmailOtp.verify!(email: email, code: code)
        Shop::EmailVerification.mark_verified!(
          session: session,
          tenant_id: @shop_tenant.id,
          email: Shop::EmailVerificationSession.normalize(email),
          session_id: request.session.id
        )
        customer = Shop::CustomerProfileMerger.link_email!(survivor: @customer, email: email)
        render json: profile_json(customer)
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue Shop::EmailOtp::Error => e
        render json: { error: e.message }, status: :bad_request
      rescue Shop::CustomerProfileMerger::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def link_phone
        phone = params.require(:phone).to_s
        code = params.require(:code).to_s
        normalized = Shop::PhoneOtp.verify!(phone: phone, code: code)
        customer = Shop::CustomerProfileMerger.link_phone!(survivor: @customer, phone: normalized)
        render json: profile_json(customer)
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue Shop::PhoneOtp::Error, Shop::PhoneNormalizer::Error => e
        render json: { error: e.message }, status: :bad_request
      rescue Shop::CustomerProfileMerger::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def require_customer!
        cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        @customer = MobileCustomer.find_by(id: cid, is_active: true) if cid.present?
        return if @customer

        render json: { error: "Требуется авторизация" }, status: :unauthorized
      end

      def profile_json(customer)
        {
          id: customer.id,
          email: customer.email,
          email_verified: customer.email_verified,
          phone: customer.phone,
          phone_verified: customer.phone_verified,
          first_name: customer.first_name,
          last_name: customer.last_name,
          name: customer.full_name.presence || customer.first_name,
          balance: 0.0,
          points: 0,
          discount_percent: 0,
          orders_count: Order.where(tenant_id: @shop_tenant.id, customer_id: customer.id).count,
          favorites_count: (session[:shop_favorites] || []).size,
          eligible_for_subscription_offer: Shop::SubscriptionOfferEligibility.check(customer, @shop_tenant)
        }
      end
    end
  end
end
