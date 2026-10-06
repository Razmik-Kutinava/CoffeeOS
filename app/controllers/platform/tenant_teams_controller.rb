# frozen_string_literal: true

module Platform
  class TenantTeamsController < BaseController
    before_action :set_tenant

    def new
      authorize @tenant, :update?
      @rows = default_rows
    end

    def create
      authorize @tenant, :update?
      members = params.fetch(:members, {}).to_unsafe_h.values

      credentials = ActiveRecord::Base.transaction do
        set_pg_context(tenant_id: @tenant.id, user_id: current_user.id)
        Platform::TenantTeamProvision.call(tenant: @tenant, members: members)
      end

      flash[:team_credentials] = credentials
      redirect_to platform_tenant_path(@tenant), notice: "Команда создана: #{credentials.size} чел."
    rescue Platform::TenantTeamProvision::Error => e
      @rows = members.presence || default_rows
      @error = e.message
      render :new, status: :unprocessable_entity
    end

    private

    def set_tenant
      @tenant = Tenant.find(params[:tenant_id])
    end

    def default_rows
      base = @tenant.slug.presence || "point"
      Platform::TenantTeamProvision.allowed_roles(@tenant).map do |role|
        { "role" => role, "name" => "", "email" => "#{role.tr('_', '-')}-#{base}@codeblack.coffee", "phone" => "" }
      end
    end
  end
end
