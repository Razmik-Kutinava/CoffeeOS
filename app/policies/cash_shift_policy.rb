class CashShiftPolicy < ApplicationPolicy
  def show?   = barista? || any_manager?
  def index?  = barista? || any_manager?

  def create?
    return false unless barista? || general_manager? || shift_manager? || uk_global_admin?

    !shift_open?
  end

  def update? = barista? || general_manager? || shift_manager? || uk_global_admin?
  def close?  = update? && shift_open?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.for_current_tenant
    end
  end
end
