#!/usr/bin/env bash
# Devcontainer tools for chart work, bootstrapping and the on-premise Terraform:
# kubectl, helm (+ helm-git), yq, jq, envsubst, gcloud, terraform (+ tflint,
# terraform-docs), pytest.
set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

KUBECTL_VERSION=v1.36.0     # within one minor of the clusters (GKE staging and kubeadm run 1.36)
HELM_VERSION=v3.17.3        # keep in step with CI (azure/setup-helm)
HELM_GIT_VERSION=1.5.2
YQ_VERSION=v4.44.3
TF_VERSION=1.15.8           # same as dep-dlm-testbed (devcontainer and CI)
TFLINT_VERSION=v0.64.0
TFDOCS_VERSION=v0.24.0      # same as dep-dlm-testbed

# --- Helpers ------------------------------------------------------------------

log()  { echo -e "${BLUE}==> $*${NC}"; }
ok()   { echo -e "${GREEN}$*${NC}"; }
fail() { echo -e "${RED}$*${NC}" >&2; exit 1; }

detect_arch() {
  case "$(uname -m)" in
    x86_64)  ARCH=amd64 ;;
    aarch64) ARCH=arm64 ;;
    *)       fail "unsupported architecture: $(uname -m)" ;;
  esac
}

install_apt_packages() {
  log "apt packages (envsubst, jq, unzip, gpg, python3 + pytest)"
  apt-get update -qq
  apt-get install -y -qq curl ca-certificates gnupg gettext-base jq unzip python3 python3-pytest
}

install_kubectl() {
  log "kubectl ${KUBECTL_VERSION}"
  curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
  chmod +x /usr/local/bin/kubectl
}

install_helm() {
  log "helm ${HELM_VERSION}"
  curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" | tar -xz -C /tmp
  mv "/tmp/linux-${ARCH}/helm" /usr/local/bin/helm
}

# Only `make deps` needs it (git+https subcharts in Chart.yaml).
install_helm_git() {
  log "helm-git ${HELM_GIT_VERSION}"
  helm plugin list | grep -q '^helm-git' && return 0
  helm plugin install https://github.com/aslafy-z/helm-git --version "$HELM_GIT_VERSION" \
    $(helm version --short | grep -q '^v4' && echo --verify=false)
}

install_yq() {
  log "yq ${YQ_VERSION}"
  curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}"
  chmod +x /usr/local/bin/yq
}

# Terraform + tflint, for the on-premise roots (terraform.mk).
install_terraform() {
  log "terraform ${TF_VERSION} + tflint ${TFLINT_VERSION}"
  curl -fsSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${ARCH}.zip"
  unzip -oq /tmp/terraform.zip terraform -d /usr/local/bin
  curl -fsSLo /tmp/tflint.zip "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_${ARCH}.zip"
  unzip -oq /tmp/tflint.zip tflint -d /usr/local/bin
  rm -f /tmp/terraform.zip /tmp/tflint.zip
}

# make tf-docs (READMEs of the on-premise roots and modules).
install_terraform_docs() {
  log "terraform-docs ${TFDOCS_VERSION}"
  curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/${TFDOCS_VERSION}/terraform-docs-${TFDOCS_VERSION}-linux-${ARCH}.tar.gz" \
    | tar -xz -C /tmp terraform-docs
  install -m 0755 /tmp/terraform-docs /usr/local/bin/terraform-docs
  rm -f /tmp/terraform-docs
}

# gcloud + GKE auth plugin: get-credentials, IAP tunnels, Secret Manager.
install_gcloud() {
  log "gcloud + gke-gcloud-auth-plugin"
  if ! command -v gcloud >/dev/null 2>&1; then
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      > /etc/apt/sources.list.d/google-cloud-sdk.list
    apt-get update -qq
  fi
  apt-get install -y -qq google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin
}

print_summary() {
  ok "kubectl $(kubectl version --client -o json | yq '.clientVersion.gitVersion') | $(helm version --short) | $(yq --version)"
  ok "$(terraform version | head -1) | tflint $(tflint --version | head -1) | $(terraform-docs --version)"
  ok "$(jq --version) | pytest $(python3 -m pytest --version 2>&1 | awk '{print $2}') | $(gcloud --version | head -1)"
  echo "Next: make lint   (gcloud auth login && gcloud auth application-default login for Terraform)"
}

# --- Main ---------------------------------------------------------------------

main() {
  detect_arch
  install_apt_packages
  install_kubectl
  install_helm
  install_helm_git
  install_yq
  install_terraform
  install_terraform_docs
  install_gcloud
  print_summary
}

main "$@"