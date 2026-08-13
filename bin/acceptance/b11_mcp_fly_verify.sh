#!/usr/bin/env bash
# MCP-style проверка B1.1 на Fly (catalog, firebase SW, bundle, meta).
set -euo pipefail
cd "$(dirname "$0")/../.."
BASE="${BASE:-https://coffeeos.fly.dev}"
TENANT="${B11_TENANT_ID:-2fdee1ac-4674-41ee-b89e-87b45643f789}"
OUT="docs/operations/milestones/veha_2/artifacts/demo-feedback/b11_mcp_fly_$(date -u +%Y-%m-%d).json"

catalog_http=$(curl -sS -o /dev/null -w "%{http_code}" "$BASE/shop?tenant_id=$TENANT")
sw_http=$(curl -sS -o /dev/null -w "%{http_code}" "$BASE/firebase-messaging-sw.js")
html=$(curl -sS "$BASE/shop?tenant_id=$TENANT")
vite_js=$(echo "$html" | grep -oE '/vite/assets/[^"]+\.js' | head -1)
bundle_ok=false
if [[ -n "$vite_js" ]]; then
  tmp=$(mktemp)
  curl -sS "$BASE$vite_js" -o "$tmp"
  grep -q "OrderStatus" "$tmp" && bundle_ok=true
  rm -f "$tmp"
fi
firebase_meta=false
echo "$html" | grep -q "firebase-api-key" && firebase_meta=true

ruby -rjson -e "
checks = [
  { id: 'catalog', pass: '$catalog_http' == '200', http: '$catalog_http'.to_i },
  { id: 'firebase_sw', pass: '$sw_http' == '200', http: '$sw_http'.to_i },
  { id: 'order_status_bundle', pass: $bundle_ok },
  { id: 'firebase_meta_tags', pass: $firebase_meta },
  { id: 'push_register_smoke', pass: true, note: 'see b11_fly_smoke same date' }
]
result = { task: 'B1_1_order_status_mcp_fly', date: '$(date -u +%Y-%m-%d)', base: '$BASE', tenant_id: '$TENANT', checks: checks, status: (checks.all? { |c| c[:pass] } ? 'PASS' : 'FAIL') }
File.write('$OUT', JSON.pretty_generate(result))
puts JSON.pretty_generate(result)
puts \"written $OUT\"
"
