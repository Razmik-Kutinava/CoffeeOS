# frozen_string_literal: true

module Manager
  # Склад точки продаж: GM + franchise (+ UK в manager через role_code general_manager).
  # shift_manager — deny (матрица RBAC).
  class InventoryPolicy < ApplicationPolicy
    def index?
      general_manager? || franchise_manager?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        scope.all
      end
    end
  end
end
