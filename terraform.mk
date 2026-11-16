# Terraform for the on-premise reference (terraform/README.md).
# Included from the Makefile: `include terraform.mk`.

TESTBED_ENV       ?= staging
TESTBED_BOOTSTRAP ?= ../dep-dlm-testbed/deploy/terraform/bootstrap
TF_RESOLVE         = eval "$$(TESTBED_BOOTSTRAP=$(TESTBED_BOOTSTRAP) terraform/scripts/resolve-tf-env.sh $(TESTBED_ENV))"

TF_ENV        ?= onprem/infra
TF_DIR         = terraform/environments/$(TF_ENV)
TERRAFORM      = terraform -chdir=$(TF_DIR)
CERTS_DIR     ?= ../dep-dlm-testbed/certs
KUBE_DIR      := $(CURDIR)/.kube

AUTO_APPROVE  ?=
TF_APPROVE     = $(if $(filter 1,$(AUTO_APPROVE)),-auto-approve,)

# OIDC inputs (vault root, validation storage), per IdP profile (same values as the testbed's Makefile).
SCOPE_PROFILE          ?= egi-dev
TOKEN_MODE             ?= managed
OIDC_CLIENT_SECRET     ?=
BOOTSTRAP_USERPASS_PWD ?= secret
USERPASS_PASSWORD      ?= secret
ifeq ($(SCOPE_PROFILE),egi-dev)
  OIDC_ISSUER_NAME    ?= egi-checkin-dev
  OIDC_ISSUER         ?= https://aai-dev.egi.eu/auth/realms/egi
  OIDC_CLIENT_ID      ?= 699e9e29-29e8-4220-8863-5306d8a7feb8
  OIDC_EXPECTED_SCOPE ?= openid profile eduperson_entitlement offline_access read:/ write:/
else ifeq ($(SCOPE_PROFILE),ls-aai-dev)
  OIDC_ISSUER_NAME    ?= lsaai-dev
  OIDC_ISSUER         ?= https://login.aai.lifescience-ri.eu/oidc/
  OIDC_CLIENT_ID      ?= 4ff05c0b-1d83-42b7-a00a-8bd162df4165
  OIDC_EXPECTED_SCOPE ?= openid profile eduperson_entitlement offline_access
endif

# Every TF_VAR_* any root uses; Terraform ignores those a root doesn't declare.
# Expand in the same shell as $(TF_RESOLVE).
define TF_VARS
TF_VAR_project_id="$$GCP_PROJECT_ID" \
	TF_VAR_region="$$GCP_REGION" \
	TF_VAR_state_bucket="$$TF_STATE_BUCKET" \
	TF_VAR_certs_dir="$(abspath $(CERTS_DIR))" \
	TF_VAR_kubernetes_ca_cert_file="$(KUBE_DIR)/onprem-ca.crt" \
	TF_VAR_scope_profile="$(SCOPE_PROFILE)" \
	TF_VAR_token_mode="$(TOKEN_MODE)" \
	TF_VAR_oidc_issuer="$(OIDC_ISSUER)" \
	TF_VAR_oidc_issuer_name="$(OIDC_ISSUER_NAME)" \
	TF_VAR_oidc_client_id="$(OIDC_CLIENT_ID)" \
	TF_VAR_oidc_client_secret="$(OIDC_CLIENT_SECRET)" \
	TF_VAR_oidc_expected_scope="$(OIDC_EXPECTED_SCOPE)" \
	TF_VAR_bootstrap_userpass_pwd="$(BOOTSTRAP_USERPASS_PWD)" \
	TF_VAR_userpass_password="$(USERPASS_PASSWORD)"
endef

# Node coordinates from the infra root's outputs.
INFRA     = terraform -chdir=terraform/environments/onprem/infra
NODE_ARGS = "$$($(INFRA) output -raw node_name)" "$$($(INFRA) output -raw zone)" "$$($(INFRA) output -raw project_id)"

.PHONY: tf-fmt tf-init tf-validate tf-plan tf-apply tf-destroy tf-output
tf-fmt: ## Format all Terraform files
	terraform fmt -recursive terraform

tf-init: ## Init a Terraform root (TF_ENV=onprem/infra|onprem/vault)
	@$(TF_RESOLVE); \
	$(TERRAFORM) init -backend-config="bucket=$$TF_STATE_BUCKET" -backend-config="prefix=$(TF_ENV)"

tf-validate: ## Validate TF_ENV (after tf-init)
	$(TERRAFORM) validate

tf-plan: ## Plan TF_ENV (CERTS_DIR=<testbed certs/>)
	@$(TF_RESOLVE); \
	$(TF_VARS) $(TERRAFORM) plan -out=tfplan

tf-apply: ## Apply TF_ENV (saved plan if present; AUTO_APPROVE=1 for CI)
	@if [ -f $(TF_DIR)/tfplan ]; then \
	  $(TERRAFORM) apply $(TF_APPROVE) tfplan && rm -f $(TF_DIR)/tfplan; \
	else \
	  $(TF_RESOLVE); $(TF_VARS) $(TERRAFORM) apply $(TF_APPROVE); \
	fi

tf-destroy: ## Destroy TF_ENV
	@$(TF_RESOLVE); \
	$(TF_VARS) $(TERRAFORM) destroy $(TF_APPROVE)

tf-output: ## Show TF_ENV's outputs
	$(TERRAFORM) output

.PHONY: onprem-kubeconfig onprem-tunnel onprem-vault-init onprem-vault-apply onprem-smoke-test
onprem-kubeconfig: ## Fetch the node's kubeconfig (.kube/config-onprem) and cluster CA via IAP
	terraform/scripts/fetch-kubeconfig.sh $(NODE_ARGS) $(KUBE_DIR)

onprem-tunnel: ## Keep an IAP tunnel to kube-apiserver open on localhost:16443 (Ctrl-C to stop)
	@echo "export KUBECONFIG=$(KUBE_DIR)/config-onprem"
	gcloud compute start-iap-tunnel $$($(INFRA) output -raw node_name) 6443 \
	  --local-host-port=localhost:16443 --zone $$($(INFRA) output -raw zone) --project $$($(INFRA) output -raw project_id)

onprem-vault-init: ## Initialise and unseal Vault on the node (once; init response -> Secret Manager)
	terraform/scripts/with-iap-tunnel.sh $(NODE_ARGS) 8200 18200 -- \
	  terraform/scripts/vault-init.sh "$$($(INFRA) output -raw vault_init_secret_id)" "$(abspath $(CERTS_DIR))/rucio_ca.pem"

onprem-vault-apply: ## Apply the vault root through an IAP tunnel (SCOPE_PROFILE, OIDC_CLIENT_SECRET)
	@[ -n "$(OIDC_CLIENT_SECRET)" ] || { echo "ERROR: OIDC_CLIENT_SECRET must be set" >&2; exit 1; }
	@$(TF_RESOLVE); \
	SECRET="$$($(INFRA) output -raw vault_init_secret_id)"; \
	export VAULT_TOKEN="$$(gcloud secrets versions access latest --secret "$${SECRET##*/}" --project "$$GCP_PROJECT_ID" | jq -r .root_token)"; \
	$(TF_VARS) terraform/scripts/with-iap-tunnel.sh $(NODE_ARGS) 8200 18200 -- \
	  terraform -chdir=terraform/environments/onprem/vault apply $(TF_APPROVE)

onprem-smoke-test: ## Smoke-test the node from pods (databases, Vault, validation storage)
	terraform/scripts/with-iap-tunnel.sh $(NODE_ARGS) 6443 16443 -- \
	  env KUBECONFIG=$(KUBE_DIR)/config-onprem pytest terraform/tests/test_deployed_infra.py -v
