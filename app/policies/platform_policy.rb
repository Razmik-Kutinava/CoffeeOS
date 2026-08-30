# frozen_string_literal: true

# IB Phase 5b: fine-grained gate для /admin (platform).
# require_uk_global_admin на base — первый рубеж; Pundit — второй.
class PlatformPolicy < ApplicationPolicy
  def access?
    user.uk_global_admin?
  end

  alias_method :index?, :access?
  alias_method :show?, :access?
  alias_method :create?, :access?
  alias_method :update?, :access?
  alias_method :destroy?, :access?
end
