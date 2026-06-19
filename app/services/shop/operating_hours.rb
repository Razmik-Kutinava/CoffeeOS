# frozen_string_literal: true

module Shop
  # B1.11: JSON и сообщения для витрины (is_open / closed_until).
  class OperatingHours
    def self.for(tenant)
      new(tenant)
    end

    def initialize(tenant)
      @tenant = tenant
      @calc = TenantOperatingHours.new(tenant)
    end

    def open_now?
      calc.open_now?
    end

    def next_open_at
      calc.next_open_at
    end

    def client_json
      open = open_now?
      next_at = open ? nil : calc.next_open_at
      {
        is_open: open,
        closed_until: next_at&.iso8601,
        closed_message: closed_message(next_at),
        timezone: tenant.timezone.presence || TenantOperatingHours::DEFAULT_TIMEZONE
      }
    end

    private

    attr_reader :tenant, :calc

    def closed_message(next_at)
      return nil unless next_at

      "Мы закрыты до следующего утра рабочего дня #{next_at.strftime('%H:%M')}"
    end
  end
end
