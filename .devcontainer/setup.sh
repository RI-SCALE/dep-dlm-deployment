#!/usr/bin/env bash
# Tools for chart work, bootstrapping and the on-premise Terraform:
# kubectl, helm (+ helm-git), yq, jq, envsubst, gcloud, terraform (+ tflint), pytest.
set -euo pipefail

case "$(uname -m)" in x86_64) ARCH=amd64 ;; aarch64) ARCH=arm64 ;; *) echo "unsupported arch"; exit 1 ;; esac

KUBECTL_VERSION=v1.36.0     # within one minor of the clusters (GKE staging and kubeadm run 1.36)
HELM_VERSION=v3.17.3        # keep in step with CI (azure/setup-helm)
HELM_GIT_VERSION=1.5.2
YQ_VERSION=v4.44.3
TF_VERSION=1.15.8           # same as dep-dlm-testbed (devcontainer and CI)
TFLINT_VERSION=v0.64.0

curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" | tar -xz -C /tmp
mv "/tmp/linux-${ARCH}/helm" /usr/local/bin/helm
curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}"
chmod +x /usr/local/bin/{kubectl,yq}

# envsubst (bootstrap.sh); jq, unzip, python3 + pytest (terraform scripts and smoke test)
apt-get update -qq && apt-get install -y -qq gettext-base jq unzip python3 python3-pytest

# Terraform + tflint, for the onprem roots (terraform.mk)
curl -fsSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${ARCH}.zip"
unzip -oq /tmp/terraform.zip terraform -d /usr/local/bin
curl -fsSLo /tmp/tflint.zip "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_${ARCH}.zip"
unzip -oq /tmp/tflint.zip tflint -d /usr/local/bin
rm -f /tmp/terraform.zip /tmp/tflint.zip

# gcloud + GKE auth plugin: get-credentials, IAP tunnels, Secret Manager
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  > /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update -qq && apt-get install -y -qq google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin

# helm-git: only `make deps` needs it (git+https subcharts in Chart.yaml).
helm plugin list | grep -q '^helm-git' || \
  helm plugin install https://github.com/aslafy-z/helm-git --version "$HELM_GIT_VERSION" \
    $(helm version --short | grep -q '^v4' && echo --verify=false)

echo "kubectl $(kubectl version --client -o json | yq '.clientVersion.gitVersion') | $(helm version --short) | $(yq --version)"
echo "$(terraform version | head -1) | tflint $(tflint --version | head -1) | $(jq --version) | pytest $(python3 -m pytest --version 2>&1 | awk '{print $2}')"
echo "Next: make lint"
