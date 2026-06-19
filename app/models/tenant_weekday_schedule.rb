# frozen_string_literal: true

# B1.11: один день недели в расписании точки продаж (чекбокс + часы).
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
  validate :closes_after_opens, if: :enabled?

  scope :enabled, -> { where(enabled: true) }
  scope :ordered, -> { order(:weekday) }

  def weekday_name
    WEEKDAY_LABELS_RU[weekday]
  end

  private

  def closes_after_opens
    return if opens_at.blank? || closes_at.blank?
    return if closes_at > opens_at

    errors.add(:closes_at, "must be after opens_at")
  end
end
