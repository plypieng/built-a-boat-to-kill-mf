#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_PORT=27100
REPLACE_EXISTING=0
SERVER_ARGS=()

find_godot() {
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then
    printf '%s\n' "${GODOT_BIN}"
    return 0
  fi

  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return 0
  fi

  if command -v godot4 >/dev/null 2>&1; then
    command -v godot4
    return 0
  fi

  if [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
    printf '%s\n' "/Applications/Godot.app/Contents/MacOS/Godot"
    return 0
  fi

  return 1
}

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --replace-existing)
        REPLACE_EXISTING=1
        ;;
      --port=*)
        SERVER_PORT="${arg#--port=}"
        SERVER_ARGS+=("$arg")
        ;;
      *)
        SERVER_ARGS+=("$arg")
        ;;
    esac
  done
}

find_project_server_pids() {
  pgrep -f -- "--path ${ROOT}.*--headless -- --server --port=${SERVER_PORT}" || true
}

ensure_port_available() {
  local existing_pids
  existing_pids="$(find_project_server_pids)"
  if [[ -n "${existing_pids}" ]]; then
    if [[ "${REPLACE_EXISTING}" -eq 1 ]]; then
      while IFS= read -r pid; do
        [[ -n "${pid}" ]] || continue
        kill "${pid}"
      done <<< "${existing_pids}"
      sleep 1
    else
      echo "Port ${SERVER_PORT} is already served by this project." >&2
      echo "Restart with --replace-existing to stop the stale server first." >&2
      exit 1
    fi
  fi

  if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"${SERVER_PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Port ${SERVER_PORT} is already in use by another process." >&2
    exit 1
  fi
}

GODOT_BIN="$(find_godot)" || {
  echo "Could not find a Godot binary. Install Godot or set GODOT_BIN." >&2
  exit 1
}

parse_args "$@"
ensure_port_available

if [[ "${#SERVER_ARGS[@]}" -gt 0 ]]; then
  exec "${GODOT_BIN}" --path "${ROOT}" --headless -- "--server" "${SERVER_ARGS[@]}"
fi

exec "${GODOT_BIN}" --path "${ROOT}" --headless -- "--server"
