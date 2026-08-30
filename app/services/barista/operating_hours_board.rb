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
      carryover_count = BoardOrdersQuery.carryover_preparing_count(
        tenant_id: tenant.id,
        cash_shift: shift
      )
      {
        schedule_conflict: schedule_conflict?,
        conflict_message: schedule_conflict? ? CONFLICT_MESSAGE : nil,
        tenant_open: TenantOperatingHours.open_now?(tenant),
        carryover_preparing_count: carryover_count,
        carryover_message: carryover_count.positive? ? carryover_message(carryover_count) : nil
      }
    end

    def carryover_message(count)
      "Незавершённые заказы с прошлой смены: #{count} в работе — доведите до выдачи."
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
