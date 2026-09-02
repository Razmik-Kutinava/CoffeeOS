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
end
