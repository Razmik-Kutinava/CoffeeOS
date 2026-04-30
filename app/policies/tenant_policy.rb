# frozen_string_literal: true

# BACK-006: Pundit policy для Tenant.
# Только uk_global_admin может управлять точками.
class TenantPolicy < ApplicationPolicy
  def index?
    user.uk_global_admin?
  end

  def show?
    user.uk_global_admin?
  end

  def create?
    user.uk_global_admin?
  end

  def update?
    user.uk_global_admin?
  end

  def destroy?
    user.uk_global_admin?
  end

  def open_as_manager?
    # Любой авторизованный пользователь может открыть точку как менеджер
    # (переключение контекста)
    true
  end

  class Scope < Scope
    def resolve
      if user.uk_global_admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
