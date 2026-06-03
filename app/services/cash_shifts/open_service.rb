# frozen_string_literal: true

module CashShifts
  class OpenService
    class Error < StandardError; end

    def self.call(tenant:, opened_by:, opening_cash: 0)
      new(tenant: tenant, opened_by: opened_by, opening_cash: opening_cash).call
    end

    def initialize(tenant:, opened_by:, opening_cash: 0)
      @tenant = tenant
      @opened_by = opened_by
      @opening_cash = opening_cash.to_d
    end

    def call
      raise Error, "Точка не указана" unless @tenant
      raise Error, "Пользователь не указан" unless @opened_by
      raise Error, "Сумма в кассе не может быть отрицательной" if @opening_cash.negative?

      CashShift.transaction do
        existing = CashShift.lock.find_by(tenant_id: @tenant.id, status: "open")
        raise Error, "Смена уже открыта" if existing

        CashShift.create!(
          tenant: @tenant,
          status: "open",
          opened_by: @opened_by,
          opened_at: Time.current,
          opening_cash: @opening_cash
        )
      end
    end
  end
end
