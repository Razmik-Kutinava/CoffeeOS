# frozen_string_literal: true

module Platform
  module TenantOnboarding
    # Единый сценарий после создания/сохранения точки в УК: модули + каталог (PTS) для точки.
    # Вызывать внутри общей транзакции с сохранением Tenant (см. TenantsController).
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
          CatalogBootstrap.ensure_pts_for_tenant!(@tenant)
        ensure
          Current.tenant_id = previous_tid
        end

        Rails.logger.info(
          {
            event: "platform.tenant_onboarding.provision",
            tenant_id: @tenant.id,
            organization_id: @tenant.organization_id,
            actor_user_id: @actor_user_id,
            slug: @tenant.slug
          }.to_json
        )

        true
      end

      private

      attr_reader :tenant, :actor_user_id, :module_params
    end
  end
end
