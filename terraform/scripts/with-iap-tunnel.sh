#!/usr/bin/env bash
# Run a command while an IAP tunnel to the node is open; closes it afterwards.
#   with-iap-tunnel.sh <instance> <zone> <project> <remote_port> <local_port> -- <command...>
# Nothing administrative on the node is public: kube-apiserver (6443) and
# Vault (8200) are reachable only this way. A tunnel already listening on
# <local_port> (e.g. `make onprem-tunnel`) is reused and left open.
set -euo pipefail
[[ $# -ge 7 ]] || { echo "usage: with-iap-tunnel.sh <instance> <zone> <project> <remote_port> <local_port> -- <command...>" >&2; exit 2; }
INSTANCE="$1" ZONE="$2" PROJECT="$3" REMOTE_PORT="$4" LOCAL_PORT="$5"
shift 5
[[ "$1" == "--" ]] && shift

port_open() { (exec 3<>"/dev/tcp/127.0.0.1/${LOCAL_PORT}") 2>/dev/null; }

if port_open; then
  echo "==> reusing the tunnel already listening on localhost:${LOCAL_PORT}" >&2
  exec "$@"
fi

LOG="$(mktemp)"
# SSH over IAP rather than start-iap-tunnel: one IAP connection that SSH
# multiplexes, instead of one IAP websocket per TCP connection (which fail
# now and then under load: SSL RECORD_LAYER_FAILURE).
gcloud compute ssh "$INSTANCE" --zone "$ZONE" --project "$PROJECT" --tunnel-through-iap --quiet -- \
  -N -L "${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT}" -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 -o StrictHostKeyChecking=no >"$LOG" 2>&1 &
TUNNEL_PID=$!
trap 'pkill -P "$TUNNEL_PID" 2>/dev/null || true; kill "$TUNNEL_PID" 2>/dev/null || true; rm -f "$LOG"' EXIT

for _ in $(seq 1 60); do
  if port_open; then
    "$@"
    exit
  fi
  kill -0 "$TUNNEL_PID" 2>/dev/null || { echo "IAP tunnel failed:" >&2; cat "$LOG" >&2; exit 1; }
  sleep 1
done
echo "IAP tunnel to ${INSTANCE}:${REMOTE_PORT} not up after 60 s:" >&2
cat "$LOG" >&2
exit 1
