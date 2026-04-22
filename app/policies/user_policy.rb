class UserPolicy < ApplicationPolicy
  # Управление персоналом — только привилегированный менеджер.
  def index?   = privileged_manager?
  def show?    = privileged_manager?
  def create?  = privileged_manager?
  def update?  = privileged_manager?
  def destroy? = uk_global_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.for_tenant(Current.tenant_id)
    end
  end
end
