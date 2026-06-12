#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
SHOP_URL="${BASE:-https://coffeeos.fly.dev}/shop?tenant_id=${B14_TENANT_ID:-2fdee1ac-4674-41ee-b89e-87b45643f789}"
OUT_DIR="docs/operations/milestones/veha_2/artifacts/demo-feedback/screenshots/b14_pwa_2026-06-11"
mkdir -p tmp "$OUT_DIR"

npx playwright install chromium 2>/dev/null || true
CHROME="$(find "$HOME/.cache/ms-playwright" -name chrome -type f 2>/dev/null | head -1)"
if [ -z "$CHROME" ]; then
  echo "no chrome found"
  exit 1
fi
export CHROME_PATH="$CHROME"

PWA_AUDITS="installable-manifest,service-worker,splash-screen,themed-omnibox,content-width,viewport,maskable-icon"

npx lighthouse "$SHOP_URL" \
  --form-factor=mobile \
  --quiet \
  --chrome-flags="--headless --no-sandbox" \
  --output=json --output=html \
  --output-path=tmp/b14_lighthouse_pwa

JSON="tmp/b14_lighthouse_pwa.report.json"
[ -f "$JSON" ] || JSON="tmp/b14_lighthouse_pwa.json"
HTML="tmp/b14_lighthouse_pwa.report.html"
[ -f "$HTML" ] || HTML="tmp/b14_lighthouse_pwa.html"

node -e "
const fs=require('fs');
const p='${JSON}';
const j=JSON.parse(fs.readFileSync(p,'utf8'));
const ids='${PWA_AUDITS}'.split(',');
const relevant=ids.map(id=>j.audits[id]).filter(Boolean);
const failed=relevant.filter(a=>a.score!==null&&a.score<1).map(a=>a.id);
const pass=failed.length===0&&relevant.length>0;
const score=pass?100:Math.round((relevant.filter(a=>a.score===1).length/relevant.length)*100);
console.log(JSON.stringify({score_percent:score,pass,failed_audit_ids:failed,audit_ids:ids},null,2));
fs.writeFileSync('tmp/b14_lighthouse_result.json', JSON.stringify({score_percent:score,pass,failed_audit_ids:failed,audit_ids:ids},null,2));
"

node bin/b14_lighthouse_screenshot.mjs "$HTML" "$OUT_DIR/lighthouse_pwa_audit.png" 2>/dev/null || cp "$HTML" "$OUT_DIR/lighthouse_pwa_audit.html"
