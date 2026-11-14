#!/usr/bin/env bash
# Tools for chart work and bootstrapping: kubectl, helm (+ helm-git), yq, envsubst, gcloud.
set -euo pipefail

case "$(uname -m)" in x86_64) ARCH=amd64 ;; aarch64) ARCH=arm64 ;; *) echo "unsupported arch"; exit 1 ;; esac

KUBECTL_VERSION=v1.36.0     # within one minor of the clusters (GKE staging runs 1.36)
HELM_VERSION=v3.17.3        # keep in step with CI (azure/setup-helm)
HELM_GIT_VERSION=1.5.2
YQ_VERSION=v4.44.3

curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" | tar -xz -C /tmp
mv "/tmp/linux-${ARCH}/helm" /usr/local/bin/helm
curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}"
chmod +x /usr/local/bin/{kubectl,yq}
apt-get update -qq && apt-get install -y -qq gettext-base   # envsubst

# gcloud + GKE auth plugin, for `gcloud container clusters get-credentials`
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  > /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update -qq && apt-get install -y -qq google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin

# helm-git: only `make deps` needs it (git+https subcharts in Chart.yaml).
helm plugin list | grep -q '^helm-git' || \
  helm plugin install https://github.com/aslafy-z/helm-git --version "$HELM_GIT_VERSION" \
    $(helm version --short | grep -q '^v4' && echo --verify=false)

echo "kubectl $(kubectl version --client -o json | yq '.clientVersion.gitVersion') | $(helm version --short) | $(yq --version)"
echo "Next: make lint"
