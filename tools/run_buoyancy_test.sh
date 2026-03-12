#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT=7300
SEED=424242
NAME="BuoyancyTest"
CLIENT_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --port=*)
      PORT="${arg#--port=}"
      ;;
    --seed=*)
      SEED="${arg#--seed=}"
      ;;
    --name=*)
      NAME="${arg#--name=}"
      ;;
    *)
      CLIENT_ARGS+=("$arg")
      ;;
  esac
done

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "${SERVER_PID}" >/dev/null 2>&1; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT INT TERM

"${ROOT}/tools/run_server.sh" --replace-existing --port="${PORT}" --seed="${SEED}" &
SERVER_PID=$!

for _ in {1..40}; do
  if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"${PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

if [[ "${#CLIENT_ARGS[@]}" -gt 0 ]]; then
  "${ROOT}/tools/run_client.sh" \
    --host=127.0.0.1 \
    --port="${PORT}" \
    --name="${NAME}" \
    --autoconnect \
    --autobuild-role=builder_sea_test_launch \
    "${CLIENT_ARGS[@]}"
else
  "${ROOT}/tools/run_client.sh" \
    --host=127.0.0.1 \
    --port="${PORT}" \
    --name="${NAME}" \
    --autoconnect \
    --autobuild-role=builder_sea_test_launch
fi

exit $?
