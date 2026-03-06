#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

GODOT_BIN="$(find_godot)" || {
  echo "Could not find a Godot binary. Install Godot or set GODOT_BIN." >&2
  exit 1
}

if [[ "$#" -gt 0 ]]; then
  exec "${GODOT_BIN}" --path "${ROOT}" --headless -- "--server" "$@"
fi

exec "${GODOT_BIN}" --path "${ROOT}" --headless -- "--server"
