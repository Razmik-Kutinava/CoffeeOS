# frozen_string_literal: true

module Barista
  # B1.11: состояние табло vs смена vs расписание.
  class OperatingHoursBoard
    CONFLICT_MESSAGE = "Смена открыта вне режима работы. После выхода закройте смену через менеджера."

    def self.context(tenant:, shift:)
      new(tenant: tenant, shift: shift).context
    end

    def initialize(tenant:, shift:)
      @tenant = tenant
      @shift = shift
    end

    def context
      {
        schedule_conflict: schedule_conflict?,
        conflict_message: schedule_conflict? ? CONFLICT_MESSAGE : nil,
        tenant_open: TenantOperatingHours.open_now?(tenant)
      }
    end

    def schedule_conflict?
      return false unless shift&.open?
      return false unless tenant.sales_point?
      return false unless tenant.weekday_schedules.enabled.exists?

      !TenantOperatingHours.open_now?(tenant)
    end

    private

    attr_reader :tenant, :shift
  end
end
