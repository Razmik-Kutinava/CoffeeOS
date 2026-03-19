#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   APP_DIR=/var/www/coffeeos/current ./run_callback_audit_alert.sh
# Optional env overrides:
#   WINDOW_MINUTES=60
#   MAX_ERROR_RATE_PERCENT=2.0
#   MIN_EVENTS=20

APP_DIR="${APP_DIR:-/var/www/coffeeos/current}"
WINDOW_MINUTES="${WINDOW_MINUTES:-60}"
MAX_ERROR_RATE_PERCENT="${MAX_ERROR_RATE_PERCENT:-2.0}"
MIN_EVENTS="${MIN_EVENTS:-20}"
RAILS_ENV="${RAILS_ENV:-production}"
LOG_FILE="${LOG_FILE:-${APP_DIR}/log/callback_audit_alert_runner.log}"

mkdir -p "$(dirname "$LOG_FILE")"
cd "$APP_DIR"
exec >> "$LOG_FILE" 2>&1

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] start callbacks:audit_alert"
echo "  RAILS_ENV=${RAILS_ENV} WINDOW_MINUTES=${WINDOW_MINUTES} MAX_ERROR_RATE_PERCENT=${MAX_ERROR_RATE_PERCENT} MIN_EVENTS=${MIN_EVENTS}"
bundle exec rake "callbacks:audit_alert[${WINDOW_MINUTES},${MAX_ERROR_RATE_PERCENT},${MIN_EVENTS}]"
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] success callbacks:audit_alert"
