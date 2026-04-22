class OrderPolicy < ApplicationPolicy
  # Барист видит только заказы своей смены/точки; менеджеры — все заказы точки.
  # Изоляция по tenant уже обеспечена RLS + for_current_tenant; здесь — роли.
  def show?          = barista? || any_manager?
  def index?         = barista? || any_manager?
  def history?       = barista? || any_manager?
  def create?        = barista?
  def update_status? = barista?
  def cancel?        = barista? || shift_manager? || office_manager? || uk_global_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.for_current_tenant
    end
  end
end
