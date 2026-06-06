# frozen_string_literal: true

module Shop
  module Api
    class OrdersController < Shop::Api::BaseController
      def create
        Rails.logger.info("[Shop::Order] Creating order for tenant #{@shop_tenant.id}, phone: #{order_params[:phone]}")
        creator = Shop::OrderCreator.new(session, tenant: @shop_tenant, request: request)
        order = creator.call!(order_params.to_h.symbolize_keys)
        Rails.logger.info("[Shop::Order] Order created: #{order.id}, total: #{order.final_amount}, status: #{order.status}")
        render json: order_create_json(order, creator)
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

      def finalize
        order = Order.where(tenant_id: @shop_tenant.id, source: :mobile).find(params[:id])
        unless order_visible_to_session_customer?(order)
          return render json: { error: "Order not found", status: 404 }, status: :not_found
        end

        if order.accepted?
          Shop::CartService.new(session, @shop_tenant.id).clear!
          Shop::PendingOrderSession.clear!(session, @shop_tenant.id)
        end

        render json: order_json(order).merge(payment_settled: order.accepted?)
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

      def order_create_json(order, creator)
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
          payload[:payment_iframe] = Shop::PaymentConfig.iframe_enabled?
          payload[:terminal_key] = Shop::PaymentConfig.terminal_key if Shop::PaymentConfig.iframe_enabled?
        end

        payload
      end

      def order_params
        params.permit(:name, :phone, :comment, :is_car_pickup, :car_number, :promo_code, :payment_method, :pickup_time)
      end

      def try_reconnect_from_params!
        order_id = params[:order_id].presence
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
          total: order.final_amount.to_f,
          status: order.status,
          discount_amount: order.discount_amount.to_f,
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
    end
  end
end
