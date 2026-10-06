# frozen_string_literal: true

namespace :platform do
  desc "Оставить одну боевую точку (Point A) на стенде: inactive на лишних sales_point. DRY_RUN=1 по умолчанию."
  task prod_single_point: :environment do
    dry_run = ENV.fetch("DRY_RUN", "1") != "0"
    keep_ids = ENV["KEEP_TENANT_IDS"]&.split(/[\s,]+/)&.presence
    keep_kitchen = ENV.fetch("KEEP_KITCHEN", "1") != "0"

    result = Platform::ProdSinglePointCleanup.call(
      dry_run: dry_run,
      keep_tenant_ids: keep_ids,
      keep_kitchen: keep_kitchen
    )

    payload = {
      task: "platform:prod_single_point",
      dry_run: result.dry_run,
      point_a: result.point_a,
      kept_tenant_ids: result.kept_tenant_ids,
      deactivated: result.deactivated,
      already_inactive: result.already_inactive,
      skipped: result.skipped,
      before: result.before,
      verification: result.verification,
      at: Time.current.iso8601
    }

    out_path = ENV["OUTPUT_JSON"]
    if out_path.present?
      File.write(out_path, JSON.pretty_generate(payload))
      puts "[platform:prod_single_point] JSON → #{out_path}"
    end

    puts JSON.pretty_generate(payload)

    unless result.verification[:pass]
      abort("[platform:prod_single_point] verification FAILED")
    end

    if dry_run
      puts "[platform:prod_single_point] DRY_RUN=1 — no changes. Run with DRY_RUN=0 to apply."
    else
      puts "[platform:prod_single_point] OK — applied."
    end
  end

  desc "Чистка прода от демо/мок-данных (Platform::ProdDataCleanup). DRY_RUN=1 по умолчанию (транзакция + ROLLBACK)."
  task prod_data_cleanup: :environment do
    dry_run = ENV.fetch("DRY_RUN", "1") != "0"
    keep_keys = ENV["KEEP_API_KEY_IDS"]&.split(/[\s,]+/)&.presence

    result = Platform::ProdDataCleanup.call(dry_run: dry_run, keep_api_key_ids: keep_keys)
    puts JSON.pretty_generate(
      task: "platform:prod_data_cleanup",
      dry_run: result.dry_run,
      steps: result.steps,
      verification: result.verification,
      at: Time.current.iso8601
    )

    abort("[platform:prod_data_cleanup] verification FAILED — rolled back") unless result.verification[:pass]
    puts(dry_run ? "[platform:prod_data_cleanup] DRY_RUN=1 — rolled back, no changes." : "[platform:prod_data_cleanup] OK — applied.")
  end

  desc "Сброс к одной точке: только владелец (УК), без сотрудников/смен/тест-точек/тест-гостей. OWNER_EMAIL обязателен, PROTECT_PHONES — через запятую. DRY_RUN=1 по умолчанию."
  task prod_single_point_reset: :environment do
    dry_run = ENV.fetch("DRY_RUN", "1") != "0"
    owner_email = ENV.fetch("OWNER_EMAIL") { abort("[platform:prod_single_point_reset] OWNER_EMAIL required") }
    phones = ENV["PROTECT_PHONES"].to_s.split(/[\s,]+/)

    result = Platform::ProdSinglePointReset.call(owner_email: owner_email, dry_run: dry_run, protect_phones: phones)
    puts JSON.pretty_generate(task: "platform:prod_single_point_reset", dry_run: result.dry_run,
                              steps: result.steps, verification: result.verification, at: Time.current.iso8601)

    abort("[platform:prod_single_point_reset] verification FAILED — rolled back") unless result.verification[:pass]
    puts(dry_run ? "[platform:prod_single_point_reset] DRY_RUN=1 — rolled back, no changes." : "[platform:prod_single_point_reset] OK — applied.")
  end
end
