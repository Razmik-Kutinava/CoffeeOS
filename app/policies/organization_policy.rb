# frozen_string_literal: true

# BACK-006: Pundit policy для Organization.
# Только uk_global_admin может управлять организациями.
class OrganizationPolicy < ApplicationPolicy
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
