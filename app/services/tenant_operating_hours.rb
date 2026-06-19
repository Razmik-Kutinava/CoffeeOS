# frozen_string_literal: true

# B1.11: открыта ли точка сейчас и когда следующее открытие (timezone точки).
class TenantOperatingHours
  DEFAULT_TIMEZONE = "Europe/Moscow"
  LOOKAHEAD_DAYS = 7

  def self.open_now?(tenant, at: Time.current)
    new(tenant, at: at).open_now?
  end

  def self.next_open_at(tenant, at: Time.current)
    new(tenant, at: at).next_open_at
  end

  def initialize(tenant, at: Time.current)
    @tenant = tenant
    @at = at
    @zone = resolve_zone(tenant.timezone)
    @local_now = at.in_time_zone(@zone)
  end

  def open_now?
    return true unless tenant.sales_point?
    return true if enabled_schedules.empty?

    row = enabled_schedules[local_weekday]
    return false unless row

    now_t = time_on_date(local_now.to_date, local_now)
    opens_t = time_on_date(local_now.to_date, row.opens_at)
    closes_t = time_on_date(local_now.to_date, row.closes_at)

    now_t >= opens_t && now_t < closes_t
  end

  def next_open_at
    return nil unless tenant.sales_point?
    return nil if open_now?
    return nil if enabled_schedules.empty?

    LOOKAHEAD_DAYS.times do |offset|
      date = local_now.to_date + offset
      row = enabled_schedules[weekday_for(date)]
      next unless row

      opens_at = time_on_date(date, row.opens_at)
      return opens_at if opens_at > local_now
    end

    nil
  end

  private

  attr_reader :tenant, :at, :zone, :local_now

  def resolve_zone(name)
    tz = name.presence || DEFAULT_TIMEZONE
    Time.find_zone(tz) || Time.find_zone(DEFAULT_TIMEZONE)
  end

  def enabled_schedules
    @enabled_schedules ||= tenant.weekday_schedules.enabled.index_by(&:weekday)
  end

  def local_weekday
    weekday_for(local_now.to_date)
  end

  # Ruby Date#wday: 0=Sun … 6=Sat → модель B1.11: 0=Mon … 6=Sun
  def weekday_for(date)
    (date.wday + 6) % 7
  end

  def time_on_date(date, clock)
    parts = extract_clock(clock)
    zone.local(date.year, date.month, date.day, parts[:hour], parts[:min], parts[:sec])
  end

  def extract_clock(value)
    t = value.is_a?(String) ? Time.zone.parse(value) : value
    { hour: t.hour, min: t.min, sec: t.sec }
  end
end
