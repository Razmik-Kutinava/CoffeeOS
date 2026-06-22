# frozen_string_literal: true

module Shop
  module Api
    class OrdersController < Shop::Api::BaseController
      include Shop::Api::OperatingHoursGuard

      before_action :reject_orders_when_closed!, only: [:create]

      def create
        Rails.logger.info("[Shop::Order] Creating order for tenant #{@shop_tenant.id}, email: #{order_params[:email]}")
        creator = Shop::OrderCreator.new(session, tenant: @shop_tenant, request: request)
        order = creator.call!(order_params.to_h.symbolize_keys)
        Rails.logger.info("[Shop::Order] Order created: #{order.id}, total: #{order.final_amount}, status: #{order.status}")
        render json: order_create_json(order, creator, recurrent: order_params[:saved_card_id].present?)
      rescue Shop::OrderCreator::Error => e
        Rails.logger.error("[Shop::Order] Failed to create order: #{e.message}")
        render json: { error: e.message, status: 422 }, status: :unprocessable_entity
      end

      def show
        order = Order.where(tenant_id: @shop_tenant.id, source: :mobile).includes(:order_items).find(params[:id])
        unless order_visible_to_session_customer?(order)
          Rails.logger.warn(
            "[Shop::Order] Order #{order.id} not visible to customer #{Shop::CustomerSession.customer_id(session, @shop_tenant.id).inspect}"
          )
          return render json: { error: "Order not found", status: 404 }, status: :not_found
        end

        Rails.logger.info(
          "[Shop::Order] Viewing order #{order.id} by customer #{Shop::CustomerSession.customer_id(session, @shop_tenant.id)}"
        )
        render json: order_json(order)
      rescue ActiveRecord::RecordNotFound
        Rails.logger.warn("[Shop::Order] Order not found: #{params[:id]}")
        render json: { error: "Order not found", status: 404 }, status: :not_found
      end

      def abandon
        try_reconnect_from_params!
        order = Order.where(tenant_id: @shop_tenant.id, source: :mobile).find(params[:id])
        unless order_visible_to_session_customer?(order)
          return render json: { error: "Order not found", status: 404 }, status: :not_found
        end

        if order.pending_payment?
          payment = order.payments.find_by(status: :pending) || order.payments.order(created_at: :desc).first
          Shop::PaymentFailureJournal.record!(
            order: order,
            payment: payment,
            reason: :guest_abandon,
            source: :customer,
            details: { trigger: "abandon_api" }
          )
          Shop::PendingOrderSession.clear!(session, @shop_tenant.id)
        end

        render json: { order_id: order.id, status: order.status }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found", status: 404 }, status: :not_found
      end

      def cancel
        order = Order.where(tenant_id: @shop_tenant.id, source: :mobile).find(params[:id])
        unless order_visible_to_session_customer?(order)
          return render json: { error: "Order not found", status: 404 }, status: :not_found
        end

        order = Shop::GuestOrderCancellationService.new(
          order: order,
          session: session,
          tenant_id: @shop_tenant.id,
          request_id: request.request_id
        ).call!

        render json: order_json(order)
      rescue Shop::GuestOrderCancellationService::Error => e
        render json: { error: e.message, status: 422 }, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found", status: 404 }, status: :not_found
      end

      def finalize
        order = Order.where(tenant_id: @shop_tenant.id, source: :mobile).find(params[:id])
        unless order_visible_to_session_customer?(order)
          return render json: { error: "Order not found", status: 404 }, status: :not_found
        end

        Payments::TbankPaymentSync.sync_order!(order: order)
        order.reload

        if order.accepted?
          Shop::CartService.new(session, @shop_tenant.id).clear!
          Shop::PendingOrderSession.clear!(session, @shop_tenant.id)
        end

        payload = order_json(order).merge(payment_settled: order.accepted?)
        saved = primary_saved_card_json(order.customer_id)
        payload[:saved_card] = saved if saved

        render json: payload
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found", status: 404 }, status: :not_found
      end

      def history
        try_reconnect_from_params!
        cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        if cid.present?
          orders = Order.where(tenant_id: @shop_tenant.id, customer_id: cid, source: :mobile)
            .order(created_at: :desc)
            .includes(:order_items)

          if ActiveModel::Type::Boolean.new.cast(params[:today])
            orders = orders.where("orders.created_at >= ?", Time.zone.today.beginning_of_day)
          end

          page = [params[:page].to_i, 1].max
          per_page = [[params[:per_page].to_i, 1].max, 50].min
          orders = orders.limit(per_page).offset((page - 1) * per_page)

          render json: orders.map { |o|
            {
              id: o.id,
              status: o.status,
              total: o.final_amount.to_f,
              created_at: o.created_at.iso8601,
              items_count: o.order_items.size
            }
          }
        else
          render json: []
        end
      end

      private

      def order_visible_to_session_customer?(order)
        cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        if cid.present? && order.customer_id.present? && order.customer_id.to_s == cid.to_s
          return true
        end

        pending_id = Shop::PendingOrderSession.order_id(session, @shop_tenant.id)
        if pending_id.present? && pending_id.to_s == order.id.to_s
          Shop::CustomerSession.set_customer_id!(session, @shop_tenant.id, order.customer_id)
          return true
        end

        token = params[:reconnect_token].presence
        if token.present?
          rebound = Shop::GuestOrderReconnect.bind!(
            session,
            tenant_id: @shop_tenant.id,
            order_id: order.id,
            token: token
          )
          return rebound.present?
        end

        false
      end

      def order_create_json(order, creator, recurrent: false)
        payload = {
          order_id: order.id,
          total: order.final_amount.to_f,
          discount: order.discount_amount.to_f,
          status: order.status,
          payment_url: creator.payment_url,
          reconnect_token: Shop::GuestOrderReconnect.token_for(order)
        }

        if creator.provider_payment_id.present?
          payload[:provider_payment_id] = creator.provider_payment_id
          if recurrent
            payload[:recurrent_charge] = true
            payload[:payment_iframe] = false
            payload.delete(:payment_url)
          else
            # B1.12-R5: только редирект на Т-Банк, без inline iframe на checkout.
            payload[:payment_iframe] = false
          end
        end

        if !recurrent && payload[:payment_url].blank? && creator.provider_payment_id.present?
          payload[:recurrent_charge] = true
        end

        payload[:card_binding] = true if creator.card_binding

        payload
      end

      def primary_saved_card_json(customer_id)
        return nil if customer_id.blank?

        card = MobilePaymentMethod.primary_for(customer_id)
        return nil unless card

        {
          id: card.id,
          payment_system: card.card_brand,
          masked_pan: card.card_masked,
          is_primary: card.is_default?,
          last_used_at: card.last_used_at&.iso8601
        }
      end

      def order_params
        params.permit(
          :name, :email, :phone, :comment, :is_car_pickup, :car_number,
          :promo_code, :payment_method, :pickup_time, :client_order_uuid, :saved_card_id
        )
      end

      def try_reconnect_from_params!
        order_id = params[:order_id].presence || params[:id].presence
        token = params[:reconnect_token].presence
        return if order_id.blank? || token.blank?

        Shop::GuestOrderReconnect.bind!(
          session,
          tenant_id: @shop_tenant.id,
          order_id: order_id,
          token: token
        )
      end

      def order_json(order)
        {
          id: order.id,
          order_number: order.order_number,
          total: order.final_amount.to_f,
          status: order.status,
          discount_amount: order.discount_amount.to_f,
          payment_settled: !order.pending_payment?,
          created_at: order.created_at.iso8601,
          reconnect_token: Shop::GuestOrderReconnect.token_for(order),
          tenant: tenant_pickup_json,
          **Shop::OrderCancellationPresenter.meta_for(order),
          items: order.order_items.map do |item|
            {
              product_name: item.product_name,
              quantity: item.quantity,
              price: item.unit_price.to_f,
              selected_modifiers: item.modifier_options&.dig("selected_modifiers") || [],
              line_total: item.total_price.to_f
            }
          end
        }
      end

      def tenant_pickup_json
        {
          name: @shop_tenant.name,
          address: @shop_tenant.address,
          city: @shop_tenant.city
        }
      end
    end
  end
end
