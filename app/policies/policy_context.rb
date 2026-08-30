# frozen_string_literal: true

# IB Phase 5: атрибутный контекст для Pundit (ABAC поверх RBAC).
# Передаётся как pundit_user из base_controller панелей staff.
class PolicyContext
  attr_reader :user, :tenant_id, :role_code, :shift, :organization_id, :module_flags, :tenant

  def self.build(user:, tenant_id:, role_code: nil, shift: :auto, tenant: nil, module_flags: nil)
    resolved_shift = resolve_shift(tenant_id, shift)
    resolved_tenant = tenant || (Tenant.find_by(id: tenant_id) if tenant_id.present?)
    resolved_flags = module_flags || load_module_flags(tenant_id)

    new(
      user: user,
      tenant_id: tenant_id,
      role_code: role_code,
      shift: resolved_shift,
      organization_id: user&.organization_id,
      module_flags: resolved_flags,
      tenant: resolved_tenant
    )
  end

  def self.resolve_shift(tenant_id, shift)
    case shift
    when :auto
      CashShift.find_by(tenant_id: tenant_id, status: "open") if tenant_id.present?
    when nil, false
      nil
    else
      shift
    end
  end

  def self.load_module_flags(tenant_id)
    return {} if tenant_id.blank?

    flags = FeatureFlag.where(tenant_id: tenant_id, module: %w[barista prep_kitchen])
    flags.each_with_object({}) do |ff, hash|
      hash[ff.module.to_sym] = ff.enabled?
    end
  end

  def initialize(user:, tenant_id:, role_code: nil, shift: nil, organization_id: nil, module_flags: {}, tenant: nil)
    @user = user
    @tenant_id = tenant_id
    @role_code = role_code
    @shift = shift
    @organization_id = organization_id
    @module_flags = module_flags
    @tenant = tenant
  end

  def shift_open?
    shift.present?
  end

  def in_shift?(order)
    return false unless shift_open?
    return false unless order.is_a?(Order)
    return false if tenant_id.blank?

    Barista::BoardOrdersQuery.shift_accessible_scope(
      tenant_id: tenant_id,
      cash_shift: shift
    ).exists?(order.id)
  end

  def module_enabled?(mod)
    key = mod.to_sym
    return true unless module_flags.key?(key)

    module_flags[key]
  end

  def production_kitchen?
    tenant&.production_kitchen?
  end

  def sales_point?
    tenant.nil? || tenant.sales_point?
  end

  def user_active?
    user&.active?
  end
end
