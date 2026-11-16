#!/usr/bin/env bash
# Run a command while an IAP tunnel to the node is open; closes it afterwards.
#   with-iap-tunnel.sh <instance> <zone> <project> <remote_port> <local_port> -- <command...>
# Nothing administrative on the node is public: kube-apiserver (6443) and
# Vault (8200) are reachable only this way.
set -euo pipefail
[[ $# -ge 7 ]] || { echo "usage: with-iap-tunnel.sh <instance> <zone> <project> <remote_port> <local_port> -- <command...>" >&2; exit 2; }
INSTANCE="$1" ZONE="$2" PROJECT="$3" REMOTE_PORT="$4" LOCAL_PORT="$5"
shift 5
[[ "$1" == "--" ]] && shift

LOG="$(mktemp)"
gcloud compute start-iap-tunnel "$INSTANCE" "$REMOTE_PORT" \
  --local-host-port="localhost:${LOCAL_PORT}" --zone "$ZONE" --project "$PROJECT" >"$LOG" 2>&1 &
TUNNEL_PID=$!
trap 'kill "$TUNNEL_PID" 2>/dev/null || true; rm -f "$LOG"' EXIT

for _ in $(seq 1 30); do
  if (exec 3<>"/dev/tcp/127.0.0.1/${LOCAL_PORT}") 2>/dev/null; then
    "$@"
    exit $?
  fi
  kill -0 "$TUNNEL_PID" 2>/dev/null || { echo "IAP tunnel failed:" >&2; cat "$LOG" >&2; exit 1; }
  sleep 1
done
echo "IAP tunnel to ${INSTANCE}:${REMOTE_PORT} not up after 30 s:" >&2
cat "$LOG" >&2
exit 1
