#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash tools/package_windows_playtest.sh <client-exe> <server-exe> [out-dir]

Example:
  bash tools/package_windows_playtest.sh \
    build/windows-client/BuiltaBoat.exe \
    build/windows-server/BuiltaBoatServer.exe \
    dist/windows-playtest

This script expects the client export and the dedicated-server export to live in
separate folders. It copies those folders into a playtest bundle and generates
simple Windows batch files for hosting and joining.
EOF
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
  usage >&2
  exit 1
fi

resolve_path() {
  local input_path="$1"
  local dir_path
  dir_path="$(cd "$(dirname "${input_path}")" && pwd)"
  printf '%s/%s\n' "${dir_path}" "$(basename "${input_path}")"
}

CLIENT_EXE="$(resolve_path "$1")"
SERVER_EXE="$(resolve_path "$2")"
OUT_DIR="${3:-${ROOT}/dist/windows-playtest}"

if [[ ! -f "${CLIENT_EXE}" ]]; then
  echo "Client export not found: ${CLIENT_EXE}" >&2
  exit 1
fi

if [[ ! -f "${SERVER_EXE}" ]]; then
  echo "Server export not found: ${SERVER_EXE}" >&2
  exit 1
fi

CLIENT_SRC_DIR="$(dirname "${CLIENT_EXE}")"
SERVER_SRC_DIR="$(dirname "${SERVER_EXE}")"
CLIENT_NAME="$(basename "${CLIENT_EXE}")"
SERVER_NAME="$(basename "${SERVER_EXE}")"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}/client" "${OUT_DIR}/server"

cp -R "${CLIENT_SRC_DIR}/." "${OUT_DIR}/client/"
cp -R "${SERVER_SRC_DIR}/." "${OUT_DIR}/server/"

cat > "${OUT_DIR}/HostAndPlay.bat" <<EOF
@echo off
set PORT=27100
if not "%~1"=="" set PORT=%~1
start "" "%~dp0client\\${CLIENT_NAME}" --autohost --port=%PORT%
EOF

cat > "${OUT_DIR}/JoinFriend.bat" <<EOF
@echo off
set HOST=127.0.0.1
if not "%~1"=="" set HOST=%~1
set PORT=27100
if not "%~2"=="" set PORT=%~2
start "" "%~dp0client\\${CLIENT_NAME}" --host=%HOST% --port=%PORT%
EOF

cat > "${OUT_DIR}/StartDedicatedServer.bat" <<EOF
@echo off
set PORT=27100
if not "%~1"=="" set PORT=%~1
set SEED=424242
if not "%~2"=="" set SEED=%~2
start "" "%~dp0server\\${SERVER_NAME}" --server --port=%PORT% --seed=%SEED%
EOF

cat > "${OUT_DIR}/README-playtest.txt" <<EOF
Built a Boat Windows Playtest Bundle
===================================

This bundle contains:
- client\\${CLIENT_NAME}
- server\\${SERVER_NAME}

Fastest host flow:
1. Double-click HostAndPlay.bat
2. The host client launches a local authoritative server automatically
3. The host shares their LAN IP and port with friends
4. Friends launch JoinFriend.bat and pass the host IP if needed

Manual dedicated-server flow:
1. Double-click StartDedicatedServer.bat
2. The host or any friend launches the client
3. Everyone joins using the host machine's IP and port

Batch file usage:
- HostAndPlay.bat [port]
- JoinFriend.bat [host-ip] [port]
- StartDedicatedServer.bat [port] [seed]

Notes:
- Host mode is still server-authoritative. It launches a local server process and then connects the client to 127.0.0.1.
- If Windows Defender asks for permission, allow private-network access for the build.
- If players cannot connect, confirm the host IP, the chosen port, and firewall permissions.
EOF

echo "Created Windows playtest bundle at ${OUT_DIR}"
