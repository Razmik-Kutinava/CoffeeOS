# frozen_string_literal: true

# TASK_102 / #75 Патч 1: legacy карты/СБП → card_binding_attempts (is_growth_event, backfill_pre_promo).
#
#   bin/rails growth_ledger:backfill:dry_run
#   bin/rails growth_ledger:backfill:apply
#
namespace :growth_ledger do
  namespace :backfill do
    desc "Dry-run: how many legacy saved methods lack a growth ledger record (no writes)"
    task dry_run: :environment do
      puts Payments::GrowthLedgerBackfill.run!(dry_run: true).to_json
    end

    desc "Create backfill_pre_promo growth records for legacy saved cards/SBP (idempotent)"
    task apply: :environment do
      puts Payments::GrowthLedgerBackfill.run!(dry_run: false).to_json
    end
  end
end
