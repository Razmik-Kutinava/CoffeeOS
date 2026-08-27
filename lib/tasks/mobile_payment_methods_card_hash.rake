# frozen_string_literal: true

# #74: backfill card_hash + деактивация cross-account дубликатов.
#
#   bin/rails mobile_payment_methods:card_hash:dry_run
#   bin/rails mobile_payment_methods:card_hash:apply
#
namespace :mobile_payment_methods do
  namespace :card_hash do
    desc "Dry-run: backfill preview + duplicate active card_hash groups (no writes)"
    task dry_run: :environment do
      Payments::MobilePaymentMethodsCardHashMigration.run!(dry_run: true)
    end

    desc "Backfill card_hash from bank_card_id and deactivate duplicate active bindings"
    task apply: :environment do
      Payments::MobilePaymentMethodsCardHashMigration.run!(dry_run: false)
    end
  end
end
