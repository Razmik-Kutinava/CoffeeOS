# frozen_string_literal: true

module Payments
  # #74 data-migration: backfill card_hash + деактивация дубликатов активных привязок.
  #
  # Порядок apply: (1) деактивировать дубли по bank_card_id, (2) backfill hash, (3) safety dedupe по card_hash.
  # Dry-run только считает/печатает, без UPDATE.
  class MobilePaymentMethodsCardHashMigration
    def self.run!(dry_run: true)
      new(dry_run: dry_run).run!
    end

    def initialize(dry_run:)
      @dry_run = dry_run
    end

    def run!
      bank_dupes = bank_card_id_duplicate_groups
      unless @dry_run
        deactivate_bank_card_id_dupes!(bank_dupes)
        backfill_card_hashes!
      end

      hash_dupes = MobilePaymentMethod.dedupe_active_card_hashes!(dry_run: @dry_run)
      pending_backfill = MobilePaymentMethod.where(payment_type: "card")
        .where(card_hash: nil)
        .where.not(bank_card_id: [nil, ""])
        .count

      payload = {
        dry_run: @dry_run,
        pending_backfill: pending_backfill,
        bank_card_id_duplicate_groups: bank_dupes.size,
        bank_card_id_duplicates: bank_dupes,
        card_hash_duplicate_groups: hash_dupes.size,
        card_hash_duplicates: hash_dupes
      }
      Rails.logger.info("[MobilePaymentMethodsCardHashMigration] #{payload.to_json}")
      puts JSON.pretty_generate(payload)
      payload
    end

    private

    def bank_card_id_duplicate_groups
      ids = MobilePaymentMethod.active_cards
        .where.not(bank_card_id: [nil, ""])
        .group(:bank_card_id)
        .having("COUNT(*) > 1")
        .pluck(:bank_card_id)

      ids.map do |bank_card_id|
        rows = MobilePaymentMethod.active_cards.where(bank_card_id: bank_card_id).order(:created_at, :id).to_a
        keeper = rows.first
        losers = rows.drop(1)
        {
          bank_card_id: bank_card_id,
          keeper_id: keeper.id,
          keeper_customer_id: keeper.customer_id,
          deactivate_ids: losers.map(&:id),
          deactivate_customer_ids: losers.map(&:customer_id)
        }
      end
    end

    def deactivate_bank_card_id_dupes!(groups)
      groups.each do |g|
        MobilePaymentMethod.where(id: g[:deactivate_ids]).update_all(is_active: false, is_default: false)
      end
    end

    def backfill_card_hashes!
      MobilePaymentMethod.where(payment_type: "card")
        .where(card_hash: nil)
        .where.not(bank_card_id: [nil, ""])
        .find_each do |row|
          hash = Payments::SavedCardStore.card_hash_for(row.bank_card_id)
          next if hash.blank?

          row.update_columns(card_hash: hash)
        end
    end
  end
end
