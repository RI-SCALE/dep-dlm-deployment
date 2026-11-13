#!/usr/bin/env bash
# Tools for chart work and bootstrapping: kubectl, helm, yq, envsubst.
set -euo pipefail

case "$(uname -m)" in x86_64) ARCH=amd64 ;; aarch64) ARCH=arm64 ;; *) echo "unsupported arch"; exit 1 ;; esac

KUBECTL_VERSION=v1.31.0
HELM_VERSION=v3.17.3        # keep in step with CI (azure/setup-helm)
YQ_VERSION=v4.44.3

curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" | tar -xz -C /tmp
mv "/tmp/linux-${ARCH}/helm" /usr/local/bin/helm
curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}"
chmod +x /usr/local/bin/{kubectl,yq}
apt-get update -qq && apt-get install -y -qq gettext-base   # envsubst

# Pinned testbed and rucio charts (vendor/); files/ and the subcharts read from them.
git submodule update --init

echo "kubectl $(kubectl version --client -o json | yq '.clientVersion.gitVersion') | $(helm version --short) | $(yq --version)"
echo "Next: make lint"
