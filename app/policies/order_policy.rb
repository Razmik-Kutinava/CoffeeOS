class OrderPolicy < ApplicationPolicy
  # RBAC + ABAC: роль + shift_open + in_shift scope (barista).
  def show?
    return false unless barista? || any_manager?
    return true if any_manager?

    in_shift?
  end

  def index?   = barista? || any_manager?
  def history? = barista? || any_manager?

  def create?
    barista? && shift_open?
  end

  def update_status?
    barista? && shift_open? && in_shift?
  end

  def cancel?
    if barista?
      shift_open? && in_shift?
    elsif shift_manager?
      shift_open?
    elsif general_manager? || uk_global_admin?
      true
    else
      false
    end
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.for_current_tenant
    end
  end
end
