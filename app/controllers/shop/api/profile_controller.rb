# frozen_string_literal: true

module Shop
  module Api
    class ProfileController < Shop::Api::BaseController
      def show
        customer = MobileCustomer.find_by(id: session[:shop_customer_id])
        if customer
          render json: {
            id: customer.id,
            name: customer.full_name.presence || customer.first_name,
            phone: customer.phone,
            balance: 0.0,
            points: 0,
            discount_percent: 0,
            orders_count: Order.where(tenant_id: @shop_tenant.id, customer_id: customer.id).count,
            favorites_count: (session[:shop_favorites] || []).size
          }
        else
          render json: {
            name: "Гость",
            balance: 0.0,
            points: 0,
            discount_percent: 0,
            orders_count: 0,
            favorites_count: (session[:shop_favorites] || []).size
          }
        end
      end
    end
  end
end
