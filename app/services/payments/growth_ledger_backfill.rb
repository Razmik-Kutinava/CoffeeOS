# frozen_string_literal: true

module Payments
  # TASK_102 / #75 Патч 1: карты/СБП, сохранённые до growth-журнала, получают запись
  # is_growth_event=true (source=backfill_pre_promo) — eligibility дальше читает только журнал.
  # Правило покрытия общее с GrowthPromo.cover_saved_method!; point_id=nil (лимит точки не трогаем).
  # Идемпотентно: покрытые phone_digest/method_hash пропускаются.
  class GrowthLedgerBackfill
    SOURCE = "backfill_pre_promo"
    METHOD_TYPES = %w[card sbp].freeze
    BATCH_SIZE = 500

    def self.run!(dry_run: false)
      new(dry_run: dry_run).run!
    end

    def initialize(dry_run:)
      @dry_run = dry_run
      @covered_digests = Set.new
      @covered_hashes = Set.new
    end

    def run!
      to_create = 0
      MobilePaymentMethod.where(payment_type: METHOD_TYPES).in_batches(of: BATCH_SIZE) do |batch|
        rows = batch.to_a
        phones = MobileCustomer.where(id: rows.map(&:customer_id).uniq).pluck(:id, :phone).to_h
        entries = rows.map { |row| entry_for(row, phones[row.customer_id]) }
        preload_coverage!(entries)

        entries.each do |entry|
          next if covered?(entry)

          to_create += 1
          create!(entry) unless @dry_run
          @covered_digests << entry[:phone_digest] if entry[:phone_digest]
          @covered_hashes << entry[:method_hash] if entry[:method_hash]
        end
      end

      payload = { dry_run: @dry_run, to_create: to_create }
      Rails.logger.info("[GrowthLedgerBackfill] #{payload.to_json}")
      payload
    end

    private

    def entry_for(row, phone)
      method_hash = row.card_hash.presence
      if method_hash.nil? && row.payment_type == "card" && row.bank_card_id.present?
        method_hash = SavedCardStore.card_hash_for(row.bank_card_id)
      end
      {
        method_type: row.payment_type,
        method_hash: method_hash,
        phone_digest: CardBindingAttempt.phone_digest_for(phone),
        account_id: row.customer_id
      }
    end

    def preload_coverage!(entries)
      digests = entries.filter_map { |e| e[:phone_digest] }.uniq - @covered_digests.to_a
      hashes = entries.filter_map { |e| e[:method_hash] }.uniq - @covered_hashes.to_a
      growth = CardBindingAttempt.where(is_growth_event: true)
      @covered_digests.merge(growth.where(phone_digest: digests).distinct.pluck(:phone_digest)) if digests.any?
      @covered_hashes.merge(growth.where(method_hash: hashes).distinct.pluck(:method_hash)) if hashes.any?
    end

    def covered?(entry)
      return true if entry[:phone_digest].nil? && entry[:method_hash].nil?

      (entry[:method_hash].nil? || @covered_hashes.include?(entry[:method_hash])) &&
        (entry[:phone_digest].nil? || @covered_digests.include?(entry[:phone_digest]))
    end

    def create!(entry)
      CardBindingAttempt.record!(
        method_type: entry[:method_type],
        method_hash: entry[:method_hash],
        phone_digest: entry[:phone_digest],
        account_id: entry[:account_id],
        point_id: nil,
        result: "ok",
        is_growth_event: true,
        source: SOURCE
      )
    end
  end
end
