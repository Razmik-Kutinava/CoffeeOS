# frozen_string_literal: true

module Barista
  # B1.11: бариста вышел при открытой смене вне расписания — пометка для менеджера.
  class ShiftScheduleLogoutHook
    NOTE_TAG = "[B1.11"

    def self.call(user:, tenant_id:)
      new(user: user, tenant_id: tenant_id).call
    end

    def initialize(user:, tenant_id:)
      @user = user
      @tenant_id = tenant_id
    end

    def call
      shift = CashShift.find_by(tenant_id: tenant_id, status: "open")
      return unless shift

      tenant = Tenant.find_by(id: tenant_id)
      return unless tenant
      return unless Barista::OperatingHoursBoard.new(tenant: tenant, shift: shift).schedule_conflict?

      line = "#{NOTE_TAG} #{Time.current.iso8601}] #{user.name} вышел: смена открыта вне расписания — закрыть через менеджера."
      note = [shift.note, line].compact.join("\n")
      shift.update!(note: note)
    end

    private

    attr_reader :user, :tenant_id
  end
end
