#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export BASE="${BASE:-https://coffeeos.fly.dev}"
export B14_TENANT_ID="${B14_TENANT_ID:-2fdee1ac-4674-41ee-b89e-87b45643f789}"

echo "=== 1/4 fly smoke ==="
ruby bin/b14_pwa_fly_smoke.rb

echo "=== 2/4 programmatic PWA audit ==="
ruby bin/b14_pwa_programmatic_audit.rb

echo "=== 3/4 browser screenshots + LCP ==="
node bin/b14_pwa_browser_shots.mjs

echo "=== 4/4 finalize acceptance JSON ==="
ruby bin/b14_finalize_acceptance.rb
