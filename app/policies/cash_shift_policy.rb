class CashShiftPolicy < ApplicationPolicy
  def show?   = barista? || any_manager?
  def index?  = barista? || any_manager?
  def create? = barista? || office_manager? || shift_manager? || uk_global_admin?
  def update? = barista? || office_manager? || shift_manager? || uk_global_admin?
  def close?  = update?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.for_current_tenant
    end
  end
end
