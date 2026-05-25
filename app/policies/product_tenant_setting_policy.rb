class ProductTenantSettingPolicy < ApplicationPolicy
  def index?  = any_manager?
  def show?   = any_manager?
  def update? = general_manager? || uk_global_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.for_current_tenant
  end
end
