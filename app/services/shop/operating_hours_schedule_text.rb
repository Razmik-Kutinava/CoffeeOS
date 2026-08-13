# frozen_string_literal: true

module Shop
  # B1.11: компактная строка расписания для шапки витрины (по tenant).
  class OperatingHoursScheduleText
    SHORT_DAYS = %w[Пн Вт Ср Чт Пт Сб Вс].freeze

    def self.for(tenant)
      new(tenant).to_s
    end

    def initialize(tenant)
      @tenant = tenant
    end

    def to_s
      rows = tenant.weekday_schedules.enabled.ordered.to_a
      return nil if rows.empty?

      groups = group_rows(rows)
      groups.map { |g| format_group(g) }.join(", ")
    end

    private

    attr_reader :tenant

    def group_rows(rows)
      rows.each_with_object([]) do |row, groups|
        key = [ clock_label(row.opens_at), clock_label(row.closes_at) ]
        if groups.last && groups.last[:key] == key && groups.last[:weekdays].last == row.weekday - 1
          groups.last[:weekdays] << row.weekday
        else
          groups << { key: key, weekdays: [ row.weekday ], opens: row.opens_at, closes: row.closes_at }
        end
      end
    end

    def format_group(group)
      days = weekday_range_label(group[:weekdays])
      "#{days} #{clock_label(group[:opens])}–#{clock_label(group[:closes])}"
    end

    def weekday_range_label(weekdays)
      return SHORT_DAYS[weekdays.first] if weekdays.size == 1

      "#{SHORT_DAYS[weekdays.first]}–#{SHORT_DAYS[weekdays.last]}"
    end

    def clock_label(value)
      t = value.is_a?(String) ? Time.zone.parse(value) : value
      t.strftime("%H:%M")
    end
  end
end
