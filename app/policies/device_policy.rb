# frozen_string_literal: true

class DevicePolicy < ApplicationPolicy
  def index?         = privileged_manager?
  def show?          = privileged_manager?
  def create?        = privileged_manager?
  def update?        = privileged_manager?
  def create_kiosk?  = privileged_manager?
  def update_tv_mode? = privileged_manager?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.for_current_tenant
    end
  end
end
