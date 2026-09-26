# frozen_string_literal: true

module Shop
  module Api
    # #78 slice-5 / Патч 1: Shop API подписки.
    class SubscriptionsController < Shop::Api::BaseController
      before_action :require_customer!

      def current
        sub = current_subscription
        return render json: { error: "Подписка не найдена" }, status: :not_found unless sub

        render json: serialize_subscription(sub)
      end

      def create
        if current_subscription
          return render json: { error: "subscription already active" }, status: :unprocessable_entity
        end

        plan = resolve_plan!
        payment_method = resolve_payment_method

        result = Subscriptions::PurchaseService.call(
          customer: @customer,
          plan: plan,
          purchase_point: @shop_tenant,
          payment_method: payment_method,
          payment_method_type: params[:payment_method_type].presence || "card",
          return_base_url: ENV.fetch("TBANK_RETURN_URL", request.base_url),
          notification_url: "#{request.base_url}/callbacks/tbank",
          auto_renew: cast_bool(params.fetch(:auto_renew, true)),
          utm_campaign: params[:utm_campaign].presence,
          utm_content: params[:utm_content].presence,
          offer_channel: params[:offer_channel].presence
        )

        payload = {
          order_id: result[:order_id],
          provider_payment_id: result[:provider_payment_id],
          payment_url: result[:payment_url],
          pending_payment: result[:pending_payment]
        }.compact

        if result[:subscription_id].present?
          sub = Subscription.find(result[:subscription_id])
          render json: serialize_subscription(sub).merge(payload).merge(subscription_id: result[:subscription_id]),
                 status: :created
        else
          render json: payload.merge(status: "pending_payment"), status: :accepted
        end
      rescue ActionController::ParameterMissing => e
        render json: { error: e.message }, status: :bad_request
      rescue Subscriptions::PurchaseService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def update_auto_renew
        sub = current_subscription
        return render json: { error: "Подписка не найдена" }, status: :not_found unless sub

        if params[:auto_renew].nil?
          return render json: { error: "auto_renew required" }, status: :unprocessable_entity
        end

        sub = Subscriptions::AutoRenewService.call(subscription: sub, auto_renew: params[:auto_renew])
        render json: serialize_subscription(sub)
      rescue Subscriptions::AutoRenewService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def cancel
        sub = current_subscription
        return render json: { error: "Подписка не найдена" }, status: :not_found unless sub

        sub = Subscriptions::CancelService.call(subscription: sub)
        render json: serialize_subscription(sub)
      rescue Subscriptions::CancelService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def confirm_payment
        sub = Subscriptions::ConfirmPaymentService.call(customer: @customer)
        render json: serialize_subscription(sub)
      rescue Subscriptions::ConfirmPaymentService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Subscriptions::PaymentFulfillment::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def require_customer!
        cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        @customer = MobileCustomer.find_by(id: cid, is_active: true) if cid.present?
        return if @customer

        render json: { error: "Требуется авторизация" }, status: :unauthorized
      end

      def current_subscription
        Subscription.for_customer(@customer.id)
          .where(status: [ :active, :past_due ])
          .order(updated_at: :desc)
          .first
      end

      def resolve_plan!
        if params[:plan_id].present?
          plan = SubscriptionPlan.find_by(id: params[:plan_id], active: true)
        elsif params[:plan_code].present?
          plan = SubscriptionPlan.find_by(code: params[:plan_code], active: true)
        else
          raise Subscriptions::PurchaseService::Error, "plan_id or plan_code required"
        end
        raise Subscriptions::PurchaseService::Error, "plan not found" unless plan

        plan
      end

      # Optional: без PM — Init redirect / bind в том же платеже.
      def resolve_payment_method
        return nil if params[:payment_method_id].blank?

        pm = MobilePaymentMethod.find_by(
          id: params[:payment_method_id],
          customer_id: @customer.id,
          is_active: true
        )
        raise Subscriptions::PurchaseService::Error, "payment method not found" unless pm

        pm
      end

      def serialize_subscription(sub)
        limit = sub.drink_limit_at_period_start.to_i
        # Патч 1: источник истины — events в 7d окне, не drinks_used_this_period.
        used = sub.usage_count_in_rolling_window
        {
          id: sub.id,
          status: sub.status,
          plan_code: sub.plan.code,
          drinks_used_this_period: used,
          drink_limit: limit,
          drinks_remaining: [ limit - used, 0 ].max,
          savings_amount: SubscriptionUsageEvent.where(subscription_id: sub.id).sum(:savings_amount).to_f,
          current_period_end: sub.current_period_end,
          auto_renew: sub.auto_renew,
          utm_campaign: sub.utm_campaign,
          utm_content: sub.utm_content,
          offer_channel: sub.offer_channel
        }
      end

      def cast_bool(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
