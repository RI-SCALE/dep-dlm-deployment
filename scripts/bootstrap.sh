#!/usr/bin/env bash
# Bootstrap one environment on the current kubectl context.
#
#   scripts/bootstrap.sh reference/staging [--repo-url URL] [--install-argocd]
#
# Renders argocd/root.yaml.tmpl from environments/<ri>/<stage>/env.yaml and
# applies it. Argo CD then installs External Secrets and the dep-dlm release;
# ordering inside the release is handled by sync waves and hooks.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_PATH="${1:?usage: bootstrap.sh <ri>/<stage> [--repo-url URL] [--install-argocd]}"; shift
REPO_URL="${REPO_URL:-https://github.com/RI-SCALE/dep-dlm-deployment.git}"
ARGOCD_VERSION="${ARGOCD_VERSION:-v2.13.3}"
INSTALL_ARGOCD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-url)       REPO_URL="$2"; shift 2 ;;
    --install-argocd) INSTALL_ARGOCD=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

ENV_FILE="${REPO_ROOT}/environments/${ENV_PATH}/env.yaml"
[[ -f "$ENV_FILE" ]] || { echo "No such environment: $ENV_FILE" >&2; exit 1; }
for cmd in kubectl yq envsubst; do
  command -v "$cmd" >/dev/null || { echo "$cmd not found" >&2; exit 1; }
done

echo "==> Target cluster: $(kubectl config current-context)"
read -r -p "Bootstrap ${ENV_PATH} here? [y/N] " ok
[[ "$ok" == [yY] ]] || exit 1

if [[ "$INSTALL_ARGOCD" -eq 1 ]]; then
  echo "==> Installing Argo CD ${ARGOCD_VERSION}"
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply --server-side --force-conflicts -n argocd \
    -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
  kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s
fi

export ENV_PATH REPO_URL
ENV_REVISION="$(yq '.envRevision' "$ENV_FILE")"
ESO_NAME="$(yq '.eso.name' "$ENV_FILE")"
ESO_NAMESPACE="$(yq '.eso.namespace' "$ENV_FILE")"
ESO_GCP_SA="$(yq '.eso.gcpServiceAccount // ""' "$ENV_FILE")"
export ENV_REVISION ESO_NAME ESO_NAMESPACE ESO_GCP_SA

echo "==> Applying root for ${ENV_PATH}"
# shellcheck disable=SC2016
envsubst '${ENV_PATH} ${REPO_URL} ${ENV_REVISION} ${ESO_NAME} ${ESO_NAMESPACE} ${ESO_GCP_SA}' \
  < "${REPO_ROOT}/argocd/root.yaml.tmpl" | kubectl apply -f -

echo "==> Done. Watch: kubectl -n argocd get applications -w"
