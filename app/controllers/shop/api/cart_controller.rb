# frozen_string_literal: true

module Shop
  module Api
    class CartController < Shop::Api::BaseController
      CART_OVERFLOW_MESSAGE = "Корзина переполнена. Мы её очистили — добавьте товары снова."

      rescue_from Shop::CartService::OverflowError, with: :handle_cart_overflow!

      def add
        Rails.logger.info("[Shop::Cart] Adding product #{params[:product_id]} to cart for tenant #{@shop_tenant.id}")
        cart_service.add!(
          product_id: params.require(:product_id),
          quantity: (params[:quantity] || 1).to_i,
          selected_modifiers: params[:selected_modifiers] || []
        )
        data = cart_service.json_lines
        render json: with_cart_reset(cart: data[:items], total: data[:total])
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.warn("[Shop::Cart] Failed to add product: #{e.message}")
        render json: { error: e.message }, status: :not_found
      rescue => e
        raise unless cookie_overflow_error?(e)
        handle_cart_overflow!
      end

      def show
        data = cart_service.json_lines
        render json: with_cart_reset(items: data[:items], total: data[:total])
      rescue => e
        raise unless cookie_overflow_error?(e)
        handle_cart_overflow!
      end

      def clear
        cart_service.clear!
        render json: with_cart_reset(items: [], total: 0)
      rescue => e
        raise unless cookie_overflow_error?(e)
        handle_cart_overflow!
      end

      def destroy
        index = params[:index].to_i
        return render json: { error: "Неверный индекс" }, status: :unprocessable_entity if index < 0
        Rails.logger.info("[Shop::Cart] Removing item at index #{index} for tenant #{@shop_tenant.id}")
        cart_service.remove!(params[:index])
        data = cart_service.json_lines
        render json: with_cart_reset(items: data[:items], total: data[:total])
      rescue => e
        raise unless cookie_overflow_error?(e)
        handle_cart_overflow!
      end

      def update
        index = params[:index].to_i
        return render json: { error: "Неверный индекс" }, status: :unprocessable_entity if index < 0

        svc = cart_service
        if params.key?(:selected_modifiers)
          # S4-блок-2: замена модификаторов (edit из Product)
          svc.replace_line!(index, selected_modifiers: params[:selected_modifiers] || [], quantity: params[:quantity])
        else
          svc.update_quantity!(index, params.require(:delta))
        end

        data = svc.json_lines
        render json: with_cart_reset(items: data[:items], total: data[:total])
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: e.message }, status: :not_found
      rescue => e
        raise unless cookie_overflow_error?(e)
        handle_cart_overflow!
      end

      private

      # Один сервис на запрос: сброс корзины чужой точки (TASK_120) виден только экземпляру, который его сделал.
      def cart_service
        @cart_service ||= Shop::CartService.new(session, @shop_tenant.id)
      end

      def with_cart_reset(payload)
        cart_service.tenant_reset? ? payload.merge(cart_reset: true) : payload
      end

      def handle_cart_overflow!(_error = nil)
        cart_service.clear!
        render json: { error: CART_OVERFLOW_MESSAGE }, status: :unprocessable_entity
      end

      # Rails 8 may not define ActionDispatch::CookieOverflow — never rescue the constant bare.
      def cookie_overflow_error?(error)
        ActionDispatch.const_defined?(:CookieOverflow) &&
          error.is_a?(ActionDispatch.const_get(:CookieOverflow))
      end
    end
  end
end
