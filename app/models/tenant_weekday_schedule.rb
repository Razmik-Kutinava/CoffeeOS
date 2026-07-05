# frozen_string_literal: true

# B1.11: один день недели в расписании точки продаж (чекбокс + часы).
# Ночная смена: closes_at < opens_at (например 09:23–01:24 = до следующего дня).
class TenantWeekdaySchedule < ApplicationRecord
  WEEKDAYS = {
    monday: 0,
    tuesday: 1,
    wednesday: 2,
    thursday: 3,
    friday: 4,
    saturday: 5,
    sunday: 6
  }.freeze

  WEEKDAY_LABELS_RU = {
    0 => "Понедельник",
    1 => "Вторник",
    2 => "Среда",
    3 => "Четверг",
    4 => "Пятница",
    5 => "Суббота",
    6 => "Воскресенье"
  }.freeze

  belongs_to :tenant

  validates :weekday, presence: true,
                      inclusion: { in: WEEKDAYS.values },
                      uniqueness: { scope: :tenant_id }
  validates :opens_at, :closes_at, presence: true, if: :enabled?
  validate :opens_and_closes_distinct, if: :enabled?

  scope :enabled, -> { where(enabled: true) }
  scope :ordered, -> { order(:weekday) }

  def weekday_name
    WEEKDAY_LABELS_RU[weekday]
  end

  # closes раньше opens → смена через полночь (закрытие на следующий календарный день).
  def overnight?
    return false if opens_at.blank? || closes_at.blank?

    clock_seconds(closes_at) < clock_seconds(opens_at)
  end

  private

  def opens_and_closes_distinct
    return if opens_at.blank? || closes_at.blank?
    return if clock_seconds(opens_at) != clock_seconds(closes_at)

    errors.add(:closes_at, "must differ from opens_at")
  end

  def clock_seconds(value)
    t = value.is_a?(String) ? Time.zone.parse(value) : value
    t.hour * 3600 + t.min * 60 + t.sec
  end
end
