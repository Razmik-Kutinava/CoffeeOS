# frozen_string_literal: true

# ABAC-011/012: feature-flag modules for staff panels.
class TenantModulePolicy < ApplicationPolicy
  def barista_panel?
    module_enabled?(:barista)
  end

  def prep_kitchen_panel?
    module_enabled?(:prep_kitchen)
  end

  def kiosk_module?
    module_enabled?(:kiosk)
  end
end
