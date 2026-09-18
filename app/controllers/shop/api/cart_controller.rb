# frozen_string_literal: true

module Shop
  module Api
    class CartController < Shop::Api::BaseController
      CART_OVERFLOW_MESSAGE = "Корзина переполнена. Мы её очистили — добавьте товары снова."

      def add
        Rails.logger.info("[Shop::Cart] Adding product #{params[:product_id]} to cart for tenant #{@shop_tenant.id}")
        Shop::CartService.new(session, @shop_tenant.id).add!(
          product_id: params.require(:product_id),
          quantity: (params[:quantity] || 1).to_i,
          selected_modifiers: params[:selected_modifiers] || []
        )
        data = Shop::CartService.new(session, @shop_tenant.id).json_lines
        render json: { cart: data[:items], total: data[:total] }
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.warn("[Shop::Cart] Failed to add product: #{e.message}")
        render json: { error: e.message }, status: :not_found
      rescue Shop::CartService::OverflowError
        handle_cart_overflow!
      rescue => e
        raise unless cookie_overflow_error?(e)
        handle_cart_overflow!
      end

      def show
        data = Shop::CartService.new(session, @shop_tenant.id).json_lines
        render json: { items: data[:items], total: data[:total] }
      end

      def clear
        Shop::CartService.new(session, @shop_tenant.id).clear!
        render json: { items: [], total: 0 }
      end

      def destroy
        index = params[:index].to_i
        return render json: { error: "Неверный индекс" }, status: :unprocessable_entity if index < 0
        Rails.logger.info("[Shop::Cart] Removing item at index #{index} for tenant #{@shop_tenant.id}")
        Shop::CartService.new(session, @shop_tenant.id).remove!(params[:index])
        data = Shop::CartService.new(session, @shop_tenant.id).json_lines
        render json: { items: data[:items], total: data[:total] }
      end

      def update
        index = params[:index].to_i
        return render json: { error: "Неверный индекс" }, status: :unprocessable_entity if index < 0

        svc = Shop::CartService.new(session, @shop_tenant.id)
        if params.key?(:selected_modifiers)
          # S4-блок-2: замена модификаторов (edit из Product)
          svc.replace_line!(index, selected_modifiers: params[:selected_modifiers] || [], quantity: params[:quantity])
        else
          svc.update_quantity!(index, params.require(:delta))
        end

        data = Shop::CartService.new(session, @shop_tenant.id).json_lines
        render json: { items: data[:items], total: data[:total] }
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: e.message }, status: :not_found
      rescue Shop::CartService::OverflowError
        handle_cart_overflow!
      rescue => e
        raise unless cookie_overflow_error?(e)
        handle_cart_overflow!
      end

      private

      def handle_cart_overflow!
        Shop::CartService.new(session, @shop_tenant.id).clear!
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
