#!/bin/bash
# Start Basic Memory (streamable-HTTP MCP on 127.0.0.1:8000) and Caddy (bearer
# token on $PORT). If either stops, stop the other and exit non-zero so Railway's
# ON_FAILURE restart policy brings the service back.
set -euo pipefail

if [ -z "${MCP_BEARER_TOKEN:-}" ] || [ "${#MCP_BEARER_TOKEN}" -lt 24 ]; then
  echo "start.sh: MCP_BEARER_TOKEN must be set to at least 24 characters" >&2
  exit 1
fi
case "$MCP_BEARER_TOKEN" in
  *[!A-Za-z0-9._~-]*) echo "start.sh: MCP_BEARER_TOKEN may only use A-Z a-z 0-9 . _ ~ -" >&2; exit 1 ;;
esac

DATA="${BM_DATA_DIR:-/data}"
export BASIC_MEMORY_CONFIG_DIR="$DATA/.basic-memory"
export BASIC_MEMORY_PROJECT_ROOT="$DATA/notes"
export BASIC_MEMORY_HOME="$DATA/notes/main"
export HOME=/home/appuser
mkdir -p "$BASIC_MEMORY_CONFIG_DIR" "$BASIC_MEMORY_HOME"
# Railway mounts volumes owned by root; the app runs as appuser (1000).
if [ "$(stat -c %u "$DATA")" != "1000" ] || [ "$(stat -c %u "$BASIC_MEMORY_HOME")" != "1000" ]; then
  chown -R 1000:1000 "$DATA"
fi

run_as_app() { setpriv --reuid=1000 --regid=1000 --init-groups --inh-caps=-all "$@"; }

echo "start.sh: Basic Memory $(basic-memory --version 2>/dev/null | awk '{print $NF}'), notes in $BASIC_MEMORY_HOME"
run_as_app basic-memory mcp --transport streamable-http --host 127.0.0.1 --port 8000 --path /mcp &
BM_PID=$!
CADDY_PID=""

stop_all() {
  [ -n "$CADDY_PID" ] && kill "$CADDY_PID" 2>/dev/null || true
  kill "$BM_PID" 2>/dev/null || true
}
trap 'stop_all; wait; exit 0' TERM INT

# Wait for Basic Memory to listen (first boot runs migrations and indexes notes).
for i in $(seq 1 240); do
  if ! kill -0 "$BM_PID" 2>/dev/null; then
    echo "start.sh: Basic Memory exited during startup" >&2
    tail -n 40 "$BASIC_MEMORY_CONFIG_DIR"/basic-memory*.log 2>/dev/null >&2 || true
    exit 1
  fi
  if python -c 'import socket,sys; s=socket.socket(); s.settimeout(1); sys.exit(s.connect_ex(("127.0.0.1",8000)))' 2>/dev/null; then
    break
  fi
  sleep 0.5
done
if ! python -c 'import socket,sys; s=socket.socket(); s.settimeout(1); sys.exit(s.connect_ex(("127.0.0.1",8000)))' 2>/dev/null; then
  echo "start.sh: Basic Memory did not listen within 120 s" >&2
  stop_all; exit 1
fi
echo "start.sh: Basic Memory MCP is up; starting the bearer-token front on :$PORT"

run_as_app caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
CADDY_PID=$!

# Poll (portable; no `wait -n`): any child gone means the service is broken.
while kill -0 "$BM_PID" 2>/dev/null && kill -0 "$CADDY_PID" 2>/dev/null; do
  sleep 2
done
echo "start.sh: a process stopped unexpectedly; exiting 1 so Railway restarts the service" >&2
tail -n 40 "$BASIC_MEMORY_CONFIG_DIR"/basic-memory*.log 2>/dev/null >&2 || true
stop_all
exit 1
