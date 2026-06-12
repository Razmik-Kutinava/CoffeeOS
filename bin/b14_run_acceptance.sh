#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export BASE="${BASE:-https://coffeeos.fly.dev}"
export B14_TENANT_ID="${B14_TENANT_ID:-2fdee1ac-4674-41ee-b89e-87b45643f789}"

echo "=== fly smoke ==="
ruby bin/b14_pwa_fly_smoke.rb

echo "=== browser + lighthouse ==="
node bin/b14_pwa_acceptance_fly.mjs

echo "=== merge ==="
ruby bin/b14_pwa_acceptance_fly.rb
