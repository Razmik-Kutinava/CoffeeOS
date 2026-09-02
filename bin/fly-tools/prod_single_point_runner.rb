# frozen_string_literal: true

# Fly / local: bin/rails runner bin/fly-tools/prod_single_point_runner.rb
# Apply: DRY_RUN=0 bin/rails runner bin/fly-tools/prod_single_point_runner.rb

dry_run = ENV.fetch("DRY_RUN", "1") != "0"

result = Platform::ProdSinglePointCleanup.call(dry_run: dry_run, keep_kitchen: true)
payload = {
  dry_run: result.dry_run,
  point_a: result.point_a,
  deactivated: result.deactivated,
  already_inactive: result.already_inactive,
  verification: result.verification,
  before: result.before
}

puts JSON.pretty_generate(payload)
abort("[prod_single_point_runner] verification FAILED") unless result.verification[:pass]

if dry_run
  puts "[prod_single_point_runner] DRY_RUN=1 — no changes applied"
else
  puts "[prod_single_point_runner] OK — applied"
end
