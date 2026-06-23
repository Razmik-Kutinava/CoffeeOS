#!/usr/bin/env bash
# CoffeeOS → Fly app coffeeos. Обход Depot 401 (ensure depot builder failed).
# Канон: docs/operations/demo/FLY_DEMO_STAND.md § Depot 401
set -euo pipefail
cd "$(dirname "$0")/.."

APP="${FLY_APP:-coffeeos}"
EXTRA_ARGS=("$@")

echo "[fly_deploy] app=${APP} --depot=false (legacy remote builder)"
exec fly deploy -a "${APP}" --depot=false "${EXTRA_ARGS[@]}"
