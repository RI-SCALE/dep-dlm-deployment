# Terraform for the on-premise reference (terraform/README.md).
# Included from the Makefile: `include terraform.mk`.

TESTBED          ?= ../dep-dlm-testbed
ONPREM_NAMESPACE ?= dep-dlm-staging
ONPREM_E2E = $(MAKE) -C $(TESTBED) GITOPS_ENV=staging TF_ENV=onprem \
	TF_DIR=$(abspath terraform/environments/onprem/infra) K8S_NAMESPACE=$(ONPREM_NAMESPACE) \
	SCOPE_PROFILE=$(SCOPE_PROFILE) TOKEN_MODE=$(TOKEN_MODE) DAEMON_MODE=daemons \
	OIDC_GRANT_TYPE=client_credentials OIDC_TOKEN_URL=$(OIDC_TOKEN_URL) \
	OIDC_ISSUER=$(OIDC_ISSUER) OIDC_CLIENT_ID=$(OIDC_CLIENT_ID) \
	OIDC_EXPECTED_SCOPE="$(OIDC_EXPECTED_SCOPE)"
OIDC_IDENTITY_EMAIL ?= marvin.gajek@cern.ch

VAULT_SAN := $(or $(VAULT_SAN),10.40.0.10)
VALSTORAGE_HOST ?= valstorage.dep-dlm-onprem.example.com

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

TF_DOC_DIRS = terraform/environments/onprem/infra terraform/environments/onprem/vault \
              terraform/modules/networking terraform/modules/onprem-node terraform/modules/vault-config

# OIDC inputs (vault root, validation storage), per IdP profile (same values as the testbed's Makefile).
# $(or …): set-but-empty variables (e.g. from a sourced env file) fall back to the defaults.
SCOPE_PROFILE          := $(or $(SCOPE_PROFILE),egi-dev)
OIDC_CLIENT_SECRET     ?=
BOOTSTRAP_USERPASS_PWD ?= secret
USERPASS_PASSWORD      ?= secret
ifeq ($(SCOPE_PROFILE),egi-dev)
  TOKEN_MODE          := $(or $(TOKEN_MODE),unmanaged)
  OIDC_ISSUER_NAME    := $(or $(OIDC_ISSUER_NAME),egi-checkin-dev)
  OIDC_ISSUER         := $(or $(OIDC_ISSUER),https://aai-dev.egi.eu/auth/realms/egi)
  OIDC_TOKEN_URL      := $(or $(OIDC_TOKEN_URL),$(OIDC_ISSUER)/protocol/openid-connect/token)
  OIDC_CLIENT_ID      := $(or $(OIDC_CLIENT_ID),699e9e29-29e8-4220-8863-5306d8a7feb8)
  OIDC_EXPECTED_SCOPE := $(or $(OIDC_EXPECTED_SCOPE),openid profile eduperson_entitlement offline_access read:/ write:/)
  TEAPOT_AUDIENCES    ?= []
  TEAPOT_EXTRA_SUBS   ?= ["0f842730-ebfb-4de6-bcbb-3a44aab5a467@egi.eu","aa886829a0a894933008498cfe62264d899422f55b408560a259311776f0e519@egi.eu"]
  OIDC_IDENTITY_SUB   ?= aa886829a0a894933008498cfe62264d899422f55b408560a259311776f0e519@egi.eu
else ifeq ($(SCOPE_PROFILE),ls-aai-dev)
  TOKEN_MODE          := $(or $(TOKEN_MODE),managed)
  OIDC_ISSUER_NAME    := $(or $(OIDC_ISSUER_NAME),lsaai-dev)
  OIDC_ISSUER         := $(or $(OIDC_ISSUER),https://login.aai.lifescience-ri.eu/oidc/)
  OIDC_TOKEN_URL      := $(or $(OIDC_TOKEN_URL),https://login.aai.lifescience-ri.eu/oidc/token)
  OIDC_CLIENT_ID      := $(or $(OIDC_CLIENT_ID),4ff05c0b-1d83-42b7-a00a-8bd162df4165)
  OIDC_EXPECTED_SCOPE := $(or $(OIDC_EXPECTED_SCOPE),openid profile eduperson_entitlement offline_access)
  TEAPOT_AUDIENCES    ?= ["https://teapot1.example.org/","https://teapot2.example.org/"]
  TEAPOT_EXTRA_SUBS   ?= ["4ff05c0b-1d83-42b7-a00a-8bd162df4165","28f7bc3a2d32a4a722f6eb24f77f7fbe42eb6471@lifescience-ri.eu"]
  OIDC_IDENTITY_SUB   ?= 28f7bc3a2d32a4a722f6eb24f77f7fbe42eb6471@lifescience-ri.eu
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
	TF_VAR_userpass_password="$(USERPASS_PASSWORD)" \
	TF_VAR_teapot_audiences='$(TEAPOT_AUDIENCES)' \
	TF_VAR_teapot_extra_subs='$(TEAPOT_EXTRA_SUBS)'
endef

# Node coordinates from the infra root's outputs.
INFRA     = terraform -chdir=terraform/environments/onprem/infra
NODE_ARGS = "$$($(INFRA) output -raw node_name)" "$$($(INFRA) output -raw zone)" "$$($(INFRA) output -raw project_id)"

.PHONY: tf-fmt
tf-fmt: ## Format all Terraform files
	terraform fmt -recursive terraform

.PHONY: tf-init
tf-init: ## Init a Terraform root (TF_ENV=onprem/infra|onprem/vault)
	@$(TF_RESOLVE); \
	$(TERRAFORM) init -backend-config="bucket=$$TF_STATE_BUCKET" -backend-config="prefix=$(TF_ENV)"

.PHONY: tf-validate
tf-validate: ## Validate TF_ENV (after tf-init)
	$(TERRAFORM) validate

.PHONY: tf-plan
tf-plan: ## Plan TF_ENV (CERTS_DIR=<testbed certs/>)
	@$(TF_RESOLVE); \
	$(TF_VARS) $(TERRAFORM) plan -out=tfplan

.PHONY: tf-apply
tf-apply: ## Apply TF_ENV (saved plan if present; AUTO_APPROVE=1 for CI)
	@if [ -f $(TF_DIR)/tfplan ]; then \
	  $(TERRAFORM) apply $(TF_APPROVE) tfplan && rm -f $(TF_DIR)/tfplan; \
	else \
	  $(TF_RESOLVE); $(TF_VARS) $(TERRAFORM) apply $(TF_APPROVE); \
	fi

.PHONY: tf-destroy
tf-destroy: ## Destroy TF_ENV
	@$(TF_RESOLVE); \
	$(TF_VARS) $(TERRAFORM) destroy $(TF_APPROVE)

.PHONY: tf-output
tf-output: ## Show TF_ENV's outputs
	$(TERRAFORM) output

.PHONY: tf-docs
tf-docs: ## Inject Terraform reference docs into each root's/module's README.md (needs terraform-docs)
	@command -v terraform-docs >/dev/null 2>&1 || { echo "terraform-docs not found (see .devcontainer/setup.sh)" >&2; exit 1; }
	@for dir in $(TF_DOC_DIRS); do \
	  echo "==> $$dir/README.md"; \
	  terraform-docs markdown table --sort-by required --output-file README.md --output-mode inject "$$dir"; \
	done

.PHONY: onprem-kubeconfig
onprem-kubeconfig: ## Fetch the node's kubeconfig (.kube/config-onprem) and cluster CA via IAP
	terraform/scripts/fetch-kubeconfig.sh $(NODE_ARGS) $(KUBE_DIR)

.PHONY: onprem-tunnel
onprem-tunnel: ## Keep an IAP tunnel to kube-apiserver open on localhost:16443 (Ctrl-C to stop)
	@echo "export KUBECONFIG=$(KUBE_DIR)/config-onprem"
	gcloud compute start-iap-tunnel $$($(INFRA) output -raw node_name) 6443 \
	  --local-host-port=localhost:16443 --zone $$($(INFRA) output -raw zone) --project $$($(INFRA) output -raw project_id)

.PHONY: onprem-vault-cert
onprem-vault-cert: ## Issue Vault's server certificate from the testbed CA (SAN: node IP, localhost for the tunnel)
	@[ -s "$(CERTS_DIR)/rucio_ca.key.pem" ] || { echo "ERROR: no CA key in $(CERTS_DIR)" >&2; exit 1; }
	ext=$$(mktemp); csr=$$(mktemp); \
	printf 'subjectAltName=IP:%s,IP:127.0.0.1,DNS:localhost\nbasicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\n' '$(VAULT_SAN)' > $$ext; \
	openssl req -new -newkey rsa:2048 -nodes -subj /CN=vault \
	  -keyout "$(CERTS_DIR)/vaultkey.pem" -out $$csr && \
	openssl x509 -req -in $$csr -CA "$(CERTS_DIR)/rucio_ca.pem" -CAkey "$(CERTS_DIR)/rucio_ca.key.pem" \
	  -set_serial 0x$$(openssl rand -hex 16) -days 365 -sha256 -extfile $$ext \
	  -out "$(CERTS_DIR)/vaultcert.pem"; \
	rc=$$?; rm -f $$ext $$csr; exit $$rc
	openssl verify -CAfile "$(CERTS_DIR)/rucio_ca.pem" "$(CERTS_DIR)/vaultcert.pem"

.PHONY: onprem-vault-init
onprem-vault-init: ## Initialise and unseal Vault on the node (once; init response -> Secret Manager)
	terraform/scripts/with-iap-tunnel.sh $(NODE_ARGS) 8200 18200 -- \
	  terraform/scripts/vault-init.sh "$$($(INFRA) output -raw vault_init_secret_id)" "$(abspath $(CERTS_DIR))/rucio_ca.pem"

.PHONY: onprem-vault-apply
onprem-vault-apply: ## Apply the vault root through an IAP tunnel (SCOPE_PROFILE, OIDC_CLIENT_SECRET)
	@[ -n "$(OIDC_CLIENT_SECRET)" ] || { echo "ERROR: OIDC_CLIENT_SECRET must be set" >&2; exit 1; }
	@$(TF_RESOLVE); \
	SECRET="$$($(INFRA) output -raw vault_init_secret_id)"; \
	export VAULT_TOKEN="$$(gcloud secrets versions access latest --secret "$${SECRET##*/}" --project "$$GCP_PROJECT_ID" | jq -r .root_token)"; \
	$(TF_VARS) terraform/scripts/with-iap-tunnel.sh $(NODE_ARGS) 8200 18200 -- \
	  terraform -chdir=terraform/environments/onprem/vault apply $(TF_APPROVE)

.PHONY: onprem-smoke-test
onprem-smoke-test: ## Smoke-test the node from pods (databases, Vault, validation storage)
	terraform/scripts/with-iap-tunnel.sh $(NODE_ARGS) 6443 16443 -- \
	  env KUBECONFIG=$(KUBE_DIR)/config-onprem pytest terraform/tests/test_deployed_infra.py -v

.PHONY: onprem-certs
onprem-certs: ## Testbed certs (validation storage SAN: its hostname) and Vault's certificate
	VALSTORAGE_EXTERNAL_SAN=$(VALSTORAGE_HOST) $(MAKE) -C $(TESTBED) certs
	$(MAKE) onprem-vault-cert

# --- E2E: the testbed's suite against the on-premise reference ----------------
.PHONY: onprem-e2e-prepare
onprem-e2e-prepare: ## Put kubeconfig and userpass-client.cfg where the testbed's E2E container expects them
	mkdir -p $(TESTBED)/.kube
	cp $(KUBE_DIR)/config-onprem $(TESTBED)/.kube/config-onprem
	terraform/scripts/with-iap-tunnel.sh $(NODE_ARGS) 6443 16443 -- \
	  env KUBECONFIG=$(abspath $(KUBE_DIR))/config-onprem bash -ec \
	  'kubectl -n $(ONPREM_NAMESPACE) get secret dep-dlm-config -o jsonpath="{.data.userpass-client\.cfg}" | base64 -d > $(TESTBED)/userpass-client.cfg'

.PHONY: onprem-e2e
onprem-e2e: onprem-e2e-prepare ## Run the testbed's E2E (init, transfers, deletion) against the on-premise reference (OIDC_CLIENT_SECRET)
	@[ -n "$(OIDC_CLIENT_SECRET)" ] || { echo "ERROR: OIDC_CLIENT_SECRET must be set" >&2; exit 1; }
	terraform/scripts/with-iap-tunnel.sh $(NODE_ARGS) 6443 16443 -- \
	  env KUBECONFIG=$(abspath $(KUBE_DIR))/config-onprem bash -ec ' \
	    $(ONPREM_E2E) init; \
	    kubectl -n $(ONPREM_NAMESPACE) exec deploy/rucio-server -c rucio-server -- \
	      rucio-admin identity add --type OIDC --id "SUB=$(OIDC_IDENTITY_SUB), ISS=$(OIDC_ISSUER)" \
	      --account randomaccount --email $(OIDC_IDENTITY_EMAIL) || true; \
	    $(ONPREM_E2E) test-rucio-transfers test-rucio-deletion'
