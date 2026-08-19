#!/usr/bin/env bash
# CoffeeOS → Fly app coffeeos.
# --remote-only: сборка на Fly builder (как CI), без локального Docker.
# --depot=false: обход Depot 401 (ensure depot builder failed).
# WSL /mnt/c/: staging на нативный ext4 — иначе timeout load build context.
# Канон: docs/operations/demo/FLY_DEMO_STAND.md § Depot 401, § WSL deploy
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${FLY_APP:-coffeeos}"
EXTRA_ARGS=("$@")

# Локальный Docker на WSL/mac ломает flyctl (unix socket / otelhttp / missing hostname).
unset DOCKER_HOST DOCKER_CONTEXT BUILDKIT_HOST

run_deploy() {
  local dir="$1"
  echo "[fly_deploy] cwd=${dir} app=${APP} --remote-only --depot=false"
  cd "$dir"
  exec fly deploy -a "${APP}" --remote-only --depot=false "${EXTRA_ARGS[@]}"
}

stage_from_windows_mount() {
  local stage="${HOME}/.cache/coffeeos-fly-deploy"
  echo "[fly_deploy] WSL /mnt/* → git archive + overlay → ${stage}"
  rm -rf "${stage}"
  mkdir -p "${stage}"
  git -C "${REPO_ROOT}" archive HEAD | tar -x -C "${stage}"

  mapfile -t changed < <(git -C "${REPO_ROOT}" ls-files -m -o --exclude-standard)
  local existing=()
  for path in "${changed[@]}"; do
    [[ -e "${REPO_ROOT}/${path}" ]] && existing+=("${path}")
  done
  if ((${#existing[@]} > 0)); then
    echo "[fly_deploy] overlay ${#existing[@]} uncommitted path(s)"
    (cd "${REPO_ROOT}" && rsync -a --relative "${existing[@]}" "${stage}/")
  fi

  run_deploy "${stage}"
}

if [[ "${REPO_ROOT}" == /mnt/* ]] && [[ -z "${FLY_DEPLOY_NO_STAGE:-}" ]]; then
  stage_from_windows_mount
else
  run_deploy "${REPO_ROOT}"
fi
