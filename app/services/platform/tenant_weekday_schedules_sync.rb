# frozen_string_literal: true

module Platform
  # B1.11: синхронизация расписания точки из формы УК (чекбоксы пн–вс + часы).
  class TenantWeekdaySchedulesSync
    def self.call(tenant:, schedule_params:)
      new(tenant: tenant, schedule_params: schedule_params).call
    end

    def initialize(tenant:, schedule_params:)
      @tenant = tenant
      @schedule_params = schedule_params.to_h
    end

    def call
      return true unless tenant.sales_point?

      rows = build_rows
      return false unless validate_at_least_one_enabled!(rows)

      TenantWeekdaySchedule.transaction do
        TenantWeekdaySchedule::WEEKDAYS.each_value do |weekday|
          row = rows.fetch(weekday)
          record = tenant.weekday_schedules.find_or_initialize_by(weekday: weekday)
          record.assign_attributes(row)
          unless record.save
            copy_errors(record)
            raise ActiveRecord::Rollback
          end
        end
      end

      tenant.errors.empty?
    end

    private

    attr_reader :tenant, :schedule_params

    def build_rows
      TenantWeekdaySchedule::WEEKDAYS.each_value.to_h do |weekday|
        raw = schedule_params[weekday.to_s] || schedule_params[weekday] || {}
        enabled = ActiveModel::Type::Boolean.new.cast(raw[:enabled] || raw["enabled"])
        enabled = false if enabled.nil?
        [ weekday, {
          enabled: enabled,
          opens_at: enabled ? parse_time(raw[:opens_at] || raw["opens_at"]) : nil,
          closes_at: enabled ? parse_time(raw[:closes_at] || raw["closes_at"]) : nil
        } ]
      end
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)&.strftime("%H:%M:%S")
    end

    def validate_at_least_one_enabled!(rows)
      return true if rows.values.any? { |r| r[:enabled] }

      tenant.errors.add(:base, "Укажите режим работы: включите хотя бы один день недели")
      false
    end

    def copy_errors(record)
      record.errors.each do |error|
        tenant.errors.add(:base, "#{record.weekday_name}: #{error.message}")
      end
    end
  end
end
