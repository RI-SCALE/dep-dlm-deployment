#!/usr/bin/env bash
# Copy the node's admin kubeconfig (via IAP SSH) and point it at the local
# end of an IAP tunnel to kube-apiserver; also write the cluster CA for
# the vault root (Kubernetes auth).
#   fetch-kubeconfig.sh <instance> <zone> <project> <out-dir> [local_port]
# Use the cluster with: make onprem-tunnel (keeps localhost:<local_port> open)
#   and KUBECONFIG=<out-dir>/config-onprem
# The file grants cluster-admin: it stays local (.kube/ is gitignored).
set -euo pipefail
INSTANCE="${1:?instance}" ZONE="${2:?zone}" PROJECT="${3:?project}" OUT="${4:?out dir}" PORT="${5:-16443}"
mkdir -p "$OUT"
KCFG="${OUT}/config-onprem"

for i in $(seq 1 40); do
  if gcloud compute ssh "$INSTANCE" --zone "$ZONE" --project "$PROJECT" --tunnel-through-iap \
       --command 'sudo test -f /etc/kubernetes/admin.conf && sudo cat /etc/kubernetes/admin.conf' \
       >"${KCFG}.tmp" 2>/dev/null && [[ -s "${KCFG}.tmp" ]]; then
    break
  fi
  echo "  [$i] waiting for kubeadm init on ${INSTANCE} (startup script still running?)..."
  sleep 30
done
[[ -s "${KCFG}.tmp" ]] || { echo "admin.conf not available on ${INSTANCE}" >&2; rm -f "${KCFG}.tmp"; exit 1; }

mv "${KCFG}.tmp" "$KCFG"
chmod 600 "$KCFG"
yq -i ".clusters[0].cluster.server = \"https://127.0.0.1:${PORT}\"" "$KCFG"
yq '.clusters[0].cluster."certificate-authority-data"' "$KCFG" | base64 -d > "${OUT}/onprem-ca.crt"
echo "==> ${KCFG} (server https://127.0.0.1:${PORT}) and ${OUT}/onprem-ca.crt"
