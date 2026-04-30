# frozen_string_literal: true

module Shop
  module Api
    class CartController < Shop::Api::BaseController
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
      end

      def show
        data = Shop::CartService.new(session, @shop_tenant.id).json_lines
        render json: { items: data[:items], total: data[:total] }
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
        Shop::CartService.new(session, @shop_tenant.id).update_quantity!(params[:index], params.require(:delta))
        data = Shop::CartService.new(session, @shop_tenant.id).json_lines
        render json: { items: data[:items], total: data[:total] }
      end
    end
  end
end
