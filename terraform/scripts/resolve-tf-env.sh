#!/usr/bin/env bash
# Prints `export ...` lines for eval in make targets:
#   eval "$(terraform/scripts/resolve-tf-env.sh staging)"
# The on-premise reference runs in the testbed's staging project, so these
# are the testbed bootstrap's outputs for that environment. Exported values
# win (CI: GitHub Environment variables); locally the rest is read from
# TESTBED_BOOTSTRAP, an initialised dep-dlm-testbed/deploy/terraform/bootstrap.
set -euo pipefail

ENV_NAME="${1:?Usage: resolve-tf-env.sh <testbed environment, e.g. staging>}"
TESTBED_BOOTSTRAP="${TESTBED_BOOTSTRAP:-../dep-dlm-testbed/deploy/terraform/bootstrap}"
VARS="GCP_PROJECT_ID GCP_REGION TF_STATE_BUCKET"

missing=()
for var in $VARS; do [[ -n "${!var:-}" ]] || missing+=("$var"); done

if [[ ${#missing[@]} -eq 0 ]]; then
  for var in $VARS; do printf 'export %s=%q\n' "$var" "${!var}"; done
  exit 0
fi

if [[ "${TF_IN_AUTOMATION:-}" == "true" || -n "${CI:-}" ]]; then
  echo "{ echo 'ERROR: running in CI but not set: ${missing[*]} (testbed bootstrap outputs for ${ENV_NAME}).' >&2; exit 1; }"
  exit 1
fi

TF_OUTPUT_ERR="$(mktemp)"
trap 'rm -f "$TF_OUTPUT_ERR"' EXIT
if ! ALL_OUTPUTS="$(terraform -chdir="$TESTBED_BOOTSTRAP" output -json 2>"$TF_OUTPUT_ERR")"; then
  echo "{ echo 'ERROR: export ${missing[*]}, or initialise the testbed bootstrap in ${TESTBED_BOOTSTRAP} (TESTBED_BOOTSTRAP=...):' >&2; cat >&2 <<'TF_ERR_EOF'"
  cat "$TF_OUTPUT_ERR"
  echo "TF_ERR_EOF"
  echo "exit 1; }"
  exit 1
fi

resolve() {
  local var="$1" output_name="$2" value
  if [[ -n "${!var:-}" ]]; then
    printf 'export %s=%q\n' "$var" "${!var}"
    return
  fi
  value="$(jq -r --arg env "$ENV_NAME" --arg key "$output_name" '(.[$key].value[$env]) // empty' <<<"$ALL_OUTPUTS")"
  if [[ -z "$value" ]]; then
    echo "{ echo 'ERROR: testbed bootstrap has no ${output_name}.${ENV_NAME}.' >&2; exit 1; }"
    exit 1
  fi
  printf 'export %s=%q\n' "$var" "$value"
}

resolve GCP_PROJECT_ID  project_ids
resolve GCP_REGION      regions
resolve TF_STATE_BUCKET state_buckets