# frozen_string_literal: true

# BACK-003: Модель промокода.
# Промокод даёт скидку на заказ, ограничен по датам и количеству использований.
class PromoCode < ApplicationRecord
  belongs_to :tenant

  validates :code, presence: true, length: { maximum: 50 }
  validates :discount_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :valid_from, presence: true
  validates :valid_to, presence: true
  validates :max_uses, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :used_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :is_active, inclusion: { in: [true, false] }

  validate :valid_to_after_valid_from
  validate :code_uniqueness_in_tenant

  scope :for_current_tenant, -> { where(tenant_id: Current.tenant_id) }
  scope :active, -> { where(is_active: true) }
  scope :currently_valid, -> { where("valid_from <= ? AND valid_to >= ?", Time.current, Time.current) }

  # Проверяет, активен ли промокод (без проверки дат и лимитов)
  def active?
    is_active
  end

  # Проверяет что промокод доступен для использования.
  # Возвращает true если:
  # - активен
  # - в пределах дат действия
  # - не превышен лимит использований
  def available?
    return false unless is_active?
    return false unless valid_from <= Time.current && valid_to >= Time.current
    return false if max_uses > 0 && used_count >= max_uses

    true
  end

  # Применяет скидку к сумме заказа.
  # Возвращает сумму скидки.
  def apply_to_order(order_total)
    return 0 unless available?
    return 0 if order_total <= 0

    (order_total * discount_percentage / 100).round(2)
  end

  # Увеличивает счётчик использований.
  def increment_usage!
    update!(used_count: used_count + 1)
  end

  private

  def valid_to_after_valid_from
    return if valid_from.blank? || valid_to.blank?
    return if valid_to > valid_from

    errors.add(:valid_to, "должна быть позже valid_from")
  end

  def code_uniqueness_in_tenant
    return if code.blank? || tenant_id.blank?

    existing = PromoCode.where(tenant_id: tenant_id, code: code).where.not(id: id)
    errors.add(:code, "уже существует в этом тенанте") if existing.exists?
  end
end
