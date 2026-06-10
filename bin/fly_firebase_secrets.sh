#!/usr/bin/env bash
# Выставляет FIREBASE_* на Fly из .env + config/secrets/firebase-service-account.json
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "missing .env" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

SA=$(ruby -rjson -e 'puts JSON.generate(JSON.parse(File.read("config/secrets/firebase-service-account.json")))')
FLY_BIN="${FLY_BIN:-fly}"
command -v "$FLY_BIN" >/dev/null 2>&1 || FLY_BIN="$HOME/.fly/bin/fly"

"$FLY_BIN" secrets set \
  "FIREBASE_API_KEY=${FIREBASE_API_KEY}" \
  "FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN}" \
  "FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}" \
  "FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}" \
  "FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}" \
  "FIREBASE_APP_ID=${FIREBASE_APP_ID}" \
  "FIREBASE_VAPID_KEY=${FIREBASE_VAPID_KEY}" \
  "FIREBASE_SERVICE_ACCOUNT_JSON=${SA}" \
  -a "${FLY_APP:-coffeeos}"
