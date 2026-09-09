# frozen_string_literal: true

module Platform
  module TenantOnboarding
    # Единый сценарий после создания/сохранения точки в УК: модули + каталог (PTS) для точки.
    # Вызывать внутри общей транзакции с сохранением Tenant (см. TenantsController).
    # Sales point: shop API key выдаётся один раз (если ещё нет usable tenant-ключа). RAW — только в return.
    class Provision
      def self.call(tenant:, actor_user_id:, module_params:)
        new(tenant: tenant, actor_user_id: actor_user_id, module_params: module_params).call
      end

      def initialize(tenant:, actor_user_id:, module_params:)
        @tenant = tenant
        @actor_user_id = actor_user_id
        @module_params = module_params
      end

      def call
        conn = ActiveRecord::Base.connection
        conn.execute("SET LOCAL app.current_user_id = #{conn.quote(@actor_user_id.to_s)}")
        TenantModuleFlags.sync!(@tenant, @module_params)

        conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(@tenant.id.to_s)}")
        previous_tid = Current.tenant_id
        begin
          Current.tenant_id = @tenant.id
          CatalogBootstrap.ensure_pts_for_tenant!(@tenant, actor_user_id: @actor_user_id)
        ensure
          Current.tenant_id = previous_tid
        end

        shop_api_key = ensure_shop_api_key!

        Rails.logger.info(
          {
            event: "platform.tenant_onboarding.provision",
            tenant_id: @tenant.id,
            organization_id: @tenant.organization_id,
            actor_user_id: @actor_user_id,
            slug: @tenant.slug,
            shop_api_key_issued: shop_api_key.present?,
            shop_api_key_prefix: shop_api_key && shop_api_key[:prefix]
          }.to_json
        )

        { ok: true, shop_api_key: shop_api_key }
      end

      private

      attr_reader :tenant, :actor_user_id, :module_params

      # Только sales_point; RAW не логируем. Повторный update не плодит ключи.
      def ensure_shop_api_key!
        return nil unless @tenant.sales_point?

        existing = Rls::GucContext.with_shop_api_key_lookup do
          ShopApiKey.usable.where(tenant_id: @tenant.id, global_ops: false).exists?
        end
        return nil if existing

        result = Shop::ApiKeys::Issue.call!(
          tenant_id: @tenant.id,
          name: "onboarding",
          global_ops: false
        )
        {
          raw: result[:raw_token],
          prefix: result[:record].token_prefix,
          id: result[:record].id
        }
      end
    end
  end
end
