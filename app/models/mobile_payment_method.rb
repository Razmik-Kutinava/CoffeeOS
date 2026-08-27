# frozen_string_literal: true

# Сохранённая карта гостя. Таблица mobile_payment_methods = UserCards в ТЗ.
# card_hash — глобальный keyed hash CardId; активный уникален на уровне БД (#74).
class MobilePaymentMethod < ApplicationRecord
  PAYMENT_TYPES = %w[card sbp ya_pay].freeze

  belongs_to :customer, class_name: "MobileCustomer", foreign_key: :customer_id, inverse_of: :mobile_payment_methods

  validates :payment_type, inclusion: { in: PAYMENT_TYPES }
  validates :card_token, presence: true, if: -> { payment_type == "card" }
  validates :customer_id, presence: true

  scope :active_cards, -> { where(is_active: true, payment_type: "card") }
  scope :active_sbp, -> { where(is_active: true, payment_type: "sbp") }
  scope :with_card_hash, ->(hash) { where(card_hash: hash) }

  # Детерминированно оставляет одну активную привязку на card_hash (oldest created_at, id).
  # dry_run: true — только отчёт; false — is_active=false для лишних.
  def self.dedupe_active_card_hashes!(dry_run: true)
    groups = active_cards.where.not(card_hash: nil)
      .group(:card_hash)
      .having("COUNT(*) > 1")
      .count

    report = []
    groups.each_key do |hash|
      rows = active_cards.where(card_hash: hash).order(:created_at, :id).to_a
      keeper = rows.first
      losers = rows.drop(1)
      report << {
        card_hash: hash,
        keeper_id: keeper.id,
        keeper_customer_id: keeper.customer_id,
        deactivate_ids: losers.map(&:id),
        deactivate_customer_ids: losers.map(&:customer_id)
      }
      next if dry_run

      losers.each do |row|
        row.update!(is_active: false, is_default: false)
      end
    end
    report
  end


  def self.for_customer(customer_id)
    active_cards.where(customer_id: customer_id).order(last_used_at: :desc, created_at: :desc)
  end

  def self.sbp_for_customer(customer_id)
    active_sbp.where(customer_id: customer_id).order(is_default: :desc, last_used_at: :desc, created_at: :desc)
  end

  def self.primary_for(customer_id)
    scope = for_customer(customer_id)
    scope.find_by(is_default: true) || scope.first
  end

  # UserCards.pan в ТЗ: *5953
  def pan_display
    digits = card_masked.to_s.gsub(/\D/, "")
    return "*#{digits[-4..]}" if digits.length >= 4

    card_masked
  end

  # UserCards.rebill_id в ТЗ
  def rebill_id
    card_token
  end
end
