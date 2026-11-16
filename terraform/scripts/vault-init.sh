#!/usr/bin/env bash
# Initialise Vault on the node once (1 key share, reference setup) and
# store the init response (unseal key, root token) in Secret Manager, where
# the node's startup script reads it to unseal after every reboot.
# Run through scripts/with-iap-tunnel.sh (make onprem-vault-init).
#   vault-init.sh <vault-init secret id> <ca file> [vault addr]
set -euo pipefail
SECRET="${1:?vault-init secret id (projects/<p>/secrets/<name>)}"
CA="${2:?CA file (testbed certs/rucio_ca.pem)}"
VAULT="${3:-https://localhost:18200}"
PROJECT="$(cut -d/ -f2 <<<"$SECRET")"
NAME="${SECRET##*/}"

vault_api() { curl -sS --cacert "$CA" "$@"; }

if [[ "$(vault_api "$VAULT/v1/sys/init" | jq -r .initialized)" == "true" ]]; then
  echo "Vault is already initialised."
else
  INIT="$(jq -n '{secret_shares: 1, secret_threshold: 1}' | vault_api -X PUT --data @- "$VAULT/v1/sys/init")"
  jq -e '.root_token' >/dev/null <<<"$INIT" || { echo "vault init failed: $INIT" >&2; exit 1; }
  printf '%s' "$INIT" | gcloud secrets versions add "$NAME" --project "$PROJECT" --data-file=- >/dev/null
  echo "==> initialised; init response stored in Secret Manager ${NAME}"
fi

if [[ "$(vault_api "$VAULT/v1/sys/seal-status" | jq -r .sealed)" == "true" ]]; then
  KEY="$(gcloud secrets versions access latest --secret "$NAME" --project "$PROJECT" | jq -r '.keys_base64[0]')"
  jq -n --arg key "$KEY" '{key: $key}' | vault_api -X PUT --data @- "$VAULT/v1/sys/unseal" >/dev/null
  echo "==> unsealed"
fi
vault_api "$VAULT/v1/sys/health" | jq '{initialized, sealed, version}'
