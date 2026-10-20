#!/bin/bash
# Boot wrapper for OpenCode 2 on Railway. Idempotent: safe to run on every boot.
set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"
PORT="${PORT:-4096}"

# 1. The server API can run shell commands, so it never starts without a credential.
if [ -z "${OPENCODE_SERVER_PASSWORD:-}" ]; then
  echo "[opencode-railway] FATAL: OPENCODE_SERVER_PASSWORD is empty. Refusing to start an unauthenticated agent server." >&2
  exit 1
fi
export OPENCODE_SERVER_PASSWORD

# 2. Everything that must survive a redeploy lives on the volume.
mkdir -p "$DATA_DIR/home" "$DATA_DIR/workspace"
export HOME="$DATA_DIR/home"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

if touch "$DATA_DIR/.write-test" 2>/dev/null; then
  rm -f "$DATA_DIR/.write-test"; writable=yes
else
  writable=NO
fi
echo "[opencode-railway] uid=$(id -u) data_dir=$DATA_DIR owner=$(stat -c %u:%g "$DATA_DIR") writable=$writable port=$PORT"
if [ "$writable" = NO ]; then
  echo "[opencode-railway] FATAL: $DATA_DIR is not writable; sessions would be lost on redeploy." >&2
  exit 1
fi

# 3. Contract block, printed on every boot so a deploying agent can read it from the log.
PUBLIC_URL="(none; no public domain on this deploy)"
[ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ] && PUBLIC_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
PRIVATE_URL="(none)"
[ -n "${RAILWAY_PRIVATE_DOMAIN:-}" ] && PRIVATE_URL="http://${RAILWAY_PRIVATE_DOMAIN}:${PORT}"
OC_VERSION="$(opencode --version 2>/dev/null || echo unknown)"
cat <<CONTRACT
[opencode-railway] ===== agent contract =====
  version      : ${OC_VERSION}
  public url   : ${PUBLIC_URL}
  private url  : ${PRIVATE_URL}
  auth         : HTTP Basic, username 'opencode', secret = variable OPENCODE_SERVER_PASSWORD
  health       : GET /  -> 200 (static web UI shell; every /api route answers 401 without credentials)
  openapi      : GET /openapi.json (authenticated)
  workspace    : ${DATA_DIR}/workspace   (default session directory; on the volume)
  state        : ${HOME}   (sessions, provider credentials, config; on the volume)
  free model   : provider 'opencode', model 'big-pickle' answers with no API key
  add a key    : POST /api/integration/<provider>/connect/key  {"key":"..."}
  example      : curl -s -u "opencode:\$OPENCODE_SERVER_PASSWORD" -X POST "\$OPENCODE_URL/api/session" -H 'content-type: application/json' -d '{}'
[opencode-railway] ==========================
CONTRACT

# 4. Run from the workspace so new sessions land in a persistent directory.
cd "$DATA_DIR/workspace"
# '::' is dual-stack: Railway's private network may be IPv6-only.
exec tini -- opencode serve --hostname '::' --port "$PORT"
