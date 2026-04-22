class ProductPolicy < ApplicationPolicy
  def show?    = barista? || any_manager? || prep_kitchen_manager? || prep_kitchen_worker?
  def index?   = show?
  def create?  = privileged_manager?
  def update?  = privileged_manager?
  def destroy? = uk_global_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
