# frozen_string_literal: true

module Shop
  module Api
    class BaseController < Shop::BaseController
      include ErrorHandler
      include Auth

      # API key / browser vitrina: Auth модуль. null_session без CSRF обнуляет cookie каждый запрос — curl/Flutter не видят корзину.
      skip_forgery_protection

      around_action :with_shop_tenant!

      private

      # TASK_93-E: session-level SET (not SET LOCAL inside long AR txn).
      # Init/Т‑Банк HTTP must not hold a pool connection in an open transaction (~15s).
      # GUC is reset in ensure so checkout reuse cannot leak tenant across requests.
      def with_shop_tenant!
        tid = resolved_shop_tenant_id
        unless tid
          return render json: {
            error: "Не задана точка: параметр tenant_id, заголовок X-Shop-Tenant или SHOP_DEFAULT_TENANT_ID в .env"
          }, status: :unprocessable_entity
        end

        tenant = Tenant.find_by(id: tid)
        unless tenant
          return render json: { error: "Точка не найдена" }, status: :not_found
        end

        @shop_tenant = tenant
        previous_tenant_id = Current.tenant_id
        Current.tenant_id = tenant.id

        conn = ActiveRecord::Base.connection
        previous_guc = conn.select_value("SELECT current_setting('app.current_tenant_id', true)")
        conn.execute("SET app.current_tenant_id = #{conn.quote(tenant.id.to_s)}")
        yield
      ensure
        Current.tenant_id = previous_tenant_id if defined?(previous_tenant_id)
        reset_shop_tenant_guc!(
          conn: (defined?(conn) ? conn : nil),
          previous_guc: (defined?(previous_guc) ? previous_guc : nil)
        )
      end

      def reset_shop_tenant_guc!(conn:, previous_guc:)
        return unless conn

        if previous_guc.present?
          conn.execute("SET app.current_tenant_id = #{conn.quote(previous_guc)}")
        else
          conn.execute("RESET app.current_tenant_id")
        end
      rescue StandardError => e
        Rails.logger.warn("[Shop::Api::BaseController] tenant GUC reset failed: #{e.class}: #{e.message}")
      end
    end
  end
end
