# frozen_string_literal: true

module Shop
  module Api
    # #77: record first successful PWA install (appinstalled) for eligibility.
    class PwaInstallsController < Shop::Api::BaseController
      def create
        customer = current_shop_customer
        return render json: { error: "Требуется авторизация" }, status: :unauthorized unless customer

        customer.mark_pwa_installed!
        render json: { ok: true, pwa_installed_at: customer.pwa_installed_at }
      end

      private

      def current_shop_customer
        cid = Shop::CustomerSession.customer_id(session, @shop_tenant.id)
        return nil if cid.blank?

        MobileCustomer.find_by(id: cid, is_active: true)
      end
    end
  end
end
