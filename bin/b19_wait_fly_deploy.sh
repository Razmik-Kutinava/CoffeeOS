#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for i in $(seq 1 20); do
  FILE=$(curl -s https://coffeeos.fly.dev/vite/.vite/manifest.json | grep -o 'assets/Product-[^"]*\.js' | head -1)
  HAS=$(curl -s "https://coffeeos.fly.dev/vite/${FILE}" | grep -c mod-chip || true)
  echo "$(date -Iseconds) ${FILE} mod-chip=${HAS}"
  if [ "${HAS}" -gt 0 ]; then
    node bin/b19_modifier_toggle_mcp.mjs
    exit $?
  fi
  sleep 60
done
echo "timeout waiting for B1.9 deploy"
exit 1
