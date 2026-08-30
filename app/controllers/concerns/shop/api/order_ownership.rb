# frozen_string_literal: true

module Shop
  module Api
    # Единая проверка visibility заказа для session customer / pending guest / reconnect_token.
    # Семантика идентична legacy OrdersController#order_visible_to_session_customer? (IB Phase 1).
    module OrderOwnership
      extend ActiveSupport::Concern

      private

      def order_visible_to_session?(order)
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

      def find_visible_order!(order_id, source: :mobile)
        order = Order.where(tenant_id: @shop_tenant.id, source: source).find(order_id)
        raise ActiveRecord::RecordNotFound unless order_visible_to_session?(order)

        order
      end

      def scope_visible_orders(source: :mobile)
        cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        scope = Order.where(tenant_id: @shop_tenant.id, source: source)
        return scope.none if cid.blank?

        scope.where(customer_id: cid)
      end

      def render_order_not_found!
        render json: { error: "Order not found", status: 404 }, status: :not_found
      end
    end
  end
end
