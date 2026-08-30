class ApplicationPolicy
  attr_reader :user, :record, :context

  def initialize(pundit_user, record)
    if pundit_user.is_a?(PolicyContext)
      @context = pundit_user
      @user    = pundit_user.user
    else
      @user    = pundit_user
      @context = nil
    end

    raise Pundit::NotAuthorizedError, "Необходима авторизация" unless user

    @record = record
  end

  def index?   = false
  def show?    = false
  def create?  = false
  def update?  = false
  def destroy? = false

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class}#resolve не реализован"
    end

    private

    attr_reader :user, :scope
  end

  private

  def context_tenant_id
    Current.tenant_id || user.tenant_id
  end

  def barista?
    user.has_role_in_context?("barista", tenant_id: context_tenant_id)
  end

  def shift_manager?
    user.has_role_in_context?("shift_manager", tenant_id: context_tenant_id)
  end

  def general_manager?
    user.has_role_in_context?("general_manager", tenant_id: context_tenant_id)
  end

  def franchise_manager?
    user.has_role_in_context?("franchise_manager", organization_id: user.organization_id)
  end

  def uk_global_admin?
    user.has_role_in_context?("ук_global_admin")
  end

  def any_manager?
    shift_manager? || general_manager? || franchise_manager? || uk_global_admin?
  end

  def privileged_manager?
    general_manager? || franchise_manager? || uk_global_admin?
  end

  def prep_kitchen_manager?
    user.has_role_in_context?("prep_kitchen_manager", tenant_id: context_tenant_id)
  end

  def prep_kitchen_worker?
    user.has_role_in_context?("prep_kitchen_worker", tenant_id: context_tenant_id)
  end

  def shift_open?
    context&.shift_open? || false
  end

  def in_shift?(order = record)
    return false unless context

    target = order.is_a?(Order) ? order : record
    context.in_shift?(target)
  end

  def module_enabled?(mod)
    context ? context.module_enabled?(mod) : true
  end

  def prep_kitchen_tenant?
    context ? context.production_kitchen? : false
  end
end
