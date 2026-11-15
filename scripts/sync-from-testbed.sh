#!/usr/bin/env bash
# Copy the files the chart deploys from a validated dep-dlm-testbed commit
# and pin the testbed subcharts (fts, opa, observability) to the same commit.
#
#   scripts/sync-from-testbed.sh <sha|tag|branch>      # fetched from GitHub
#   scripts/sync-from-testbed.sh ../dep-dlm-testbed    # or a local checkout
#   RUCIO_REF=<sha|tag|branch> scripts/sync-from-testbed.sh <...>   # also bump the rucio fork
#
# Refs are always pinned as full commit SHAs. Paths keep the testbed's layout,
# so the ConfigMap keys stay identical to the testbed's.
# Then: make deps, make lint, review `git diff`, update PROMOTION.md.
set -euo pipefail

TESTBED_URL="https://github.com/RI-SCALE/dep-dlm-testbed.git"
RUCIO_URL="https://github.com/mgajek-cern/helm-charts.git"

SRC="${1:?usage: sync-from-testbed.sh <testbed commit|tag|branch, or path to a checkout>}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILES="${REPO_ROOT}/charts/dep-dlm/files"
CHART_YAML="${REPO_ROOT}/charts/dep-dlm/Chart.yaml"

if [[ -d "$SRC" ]]; then
  TESTBED="$SRC"
  [[ -z "$(git -C "$TESTBED" status --porcelain)" ]] \
    || { echo "Testbed checkout has uncommitted changes; check out the validated commit" >&2; exit 1; }
else
  # A ref: fetch exactly that commit into a temporary checkout.
  TESTBED="$(mktemp -d)"
  trap 'rm -rf "$TESTBED"' EXIT
  git -C "$TESTBED" init -q
  git -C "$TESTBED" fetch -q --depth 1 "$TESTBED_URL" "$SRC" \
    || { echo "Cannot fetch '${SRC}' from ${TESTBED_URL} (use a full commit SHA, a tag or a branch)" >&2; exit 1; }
  git -C "$TESTBED" -c advice.detachedHead=false checkout -q FETCH_HEAD
fi

[[ -d "${TESTBED}/patches" && -d "${TESTBED}/configs/opa" ]] \
  || { echo "Not a dep-dlm-testbed checkout: ${TESTBED}" >&2; exit 1; }
SHA="$(git -C "$TESTBED" rev-parse HEAD)"

# Only what the chart deploys (see templates/configmaps.yaml).
ALLOW=(
  patches/rucio
  patches/fts
  scripts/rucio
  scripts/ingest_policies.py
  configs/fts/gfal2_http_plugin.conf
  configs/opa/authz.rego
  configs/opa/odrl
  configs/opa/vendor/opa-ri-scale/dep
)
rm -rf "$FILES"
for p in "${ALLOW[@]}"; do
  [[ -e "${TESTBED}/${p}" ]] || { echo "Missing in testbed ${SHA:0:7}: ${p}" >&2; exit 1; }
  mkdir -p "${FILES}/$(dirname "$p")"
  cp -R "${TESTBED}/${p}" "${FILES}/${p}"
done
find "$FILES" -name '*_test.rego' -delete

sed -i.bak -E "s#(dep-dlm-testbed(\.git)?@[^?\"]+\?ref=)[^\"]+#\1${SHA}#" "$CHART_YAML"

if [[ -n "${RUCIO_REF:-}" ]]; then
  # Resolve tags/branches to the commit they point at now.
  if [[ "$RUCIO_REF" =~ ^[0-9a-f]{40}$ ]]; then
    RUCIO_SHA="$RUCIO_REF"
  else
    RUCIO_SHA="$(git ls-remote "$RUCIO_URL" "$RUCIO_REF" "${RUCIO_REF}^{}" | tail -1 | cut -f1)"
    [[ -n "$RUCIO_SHA" ]] || { echo "Cannot resolve RUCIO_REF='${RUCIO_REF}' in ${RUCIO_URL}" >&2; exit 1; }
  fi
  sed -i.bak -E "s#(helm-charts(\.git)?@[^?\"]+\?ref=)[^\"]+#\1${RUCIO_SHA}#" "$CHART_YAML"
  echo "==> rucio chart refs pinned to ${RUCIO_SHA:0:7}"
fi
rm -f "${CHART_YAML}.bak"

echo "==> files/ synced from dep-dlm-testbed ${SHA:0:7}; testbed chart refs pinned to it"
echo "Next: make deps && make lint, review 'git diff', record ${SHA} in PROMOTION.md"
