# frozen_string_literal: true

module Shop
  module Api
    class OrdersController < Shop::Api::BaseController
      def create
        Rails.logger.info("[Shop::Order] Creating order for tenant #{@shop_tenant.id}, phone: #{order_params[:phone]}")
        order = Shop::OrderCreator.new(session, tenant: @shop_tenant).call!(order_params.to_h.symbolize_keys)
        Rails.logger.info("[Shop::Order] Order created: #{order.id}, total: #{order.final_amount}, status: #{order.status}")
        render json: {
          order_id: order.id,
          total: order.final_amount.to_f,
          discount: order.discount_amount.to_f,
          status: order.status
        }
      rescue Shop::OrderCreator::Error => e
        Rails.logger.error("[Shop::Order] Failed to create order: #{e.message}")
        render json: { error: e.message, status: 422 }, status: :unprocessable_entity
      end

      def show
        order = Order.where(tenant_id: @shop_tenant.id, source: :mobile).includes(:order_items).find(params[:id])
        Rails.logger.info("[Shop::Order] Viewing order #{order.id} by customer #{session[:shop_customer_id]}")
        render json: order_json(order)
      rescue ActiveRecord::RecordNotFound
        Rails.logger.warn("[Shop::Order] Order not found: #{params[:id]}")
        render json: { error: "Order not found", status: 404 }, status: :not_found
      end

      def history
        cid = session[:shop_customer_id]
        if cid.present?
          orders = Order.where(tenant_id: @shop_tenant.id, customer_id: cid, source: :mobile)
            .order(created_at: :desc)
            .includes(:order_items)

          # Пагинация
          page = [params[:page].to_i, 1].max
          per_page = [params[:per_page].to_i, 1, 50].min
          orders = orders.limit(per_page).offset((page - 1) * per_page)

          render json: orders.map { |o|
            {
              id: o.id,
              status: o.status,
              total: o.final_amount.to_f,
              created_at: o.created_at.iso8601,
              items_count: o.order_items.size
            }
          }.map { |o| o.merge(page: page, per_page: per_page) }
        else
          render json: []
        end
      end

      private

      def order_params
        params.permit(:name, :phone, :comment, :is_car_pickup, :car_number, :promo_code, :payment_method, :pickup_time)
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
