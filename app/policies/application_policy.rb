class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "Необходима авторизация" unless user

    @user   = user
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

  def barista?
    user.has_role?("barista")
  end

  def shift_manager?
    user.has_role?("shift_manager")
  end

  def office_manager?
    user.has_role?("office_manager")
  end

  def franchise_manager?
    user.has_role?("franchise_manager")
  end

  def uk_global_admin?
    user.uk_global_admin?
  end

  def any_manager?
    shift_manager? || office_manager? || franchise_manager? || uk_global_admin?
  end

  def privileged_manager?
    office_manager? || franchise_manager? || uk_global_admin?
  end

  def prep_kitchen_manager?
    user.has_role?("prep_kitchen_manager")
  end

  def prep_kitchen_worker?
    user.has_role?("prep_kitchen_worker")
  end
end
