SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

CHART   := charts/dep-dlm
ENV     ?= reference/staging
TESTBED ?= ../dep-dlm-testbed

.PHONY: help
help: ## Show targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: sync
sync: ## Copy deployed files from a validated testbed checkout, pin its charts (TESTBED=path [RUCIO_REF=sha])
	RUCIO_REF=$(RUCIO_REF) scripts/sync-from-testbed.sh $(TESTBED)

.PHONY: deps
deps: ## Vendor the subcharts (helm-git); commit charts/dep-dlm/charts/ and Chart.lock
	helm dependency update $(CHART)

.PHONY: lint
lint: ## Lint and render every environment
	@for env in environments/*/*/; do \
	  echo "==> $$env"; \
	  helm lint $(CHART) -f $$env/values.yaml >/dev/null || exit 1; \
	  helm template dep-dlm $(CHART) -f $$env/values.yaml >/dev/null || exit 1; \
	done

.PHONY: template
template: ## Render one environment (ENV=<ri>/<stage>)
	helm template dep-dlm $(CHART) -f environments/$(ENV)/values.yaml

.PHONY: bootstrap
bootstrap: ## Bootstrap ENV on the current kubectl context (ARGS="--install-argocd")
	scripts/bootstrap.sh $(ENV) $(ARGS)

.PHONY: argocd-open
argocd-open: ## Open the Argo CD UI (port-forward to https://localhost:8080 until Ctrl-C; user admin)
	@echo "user: admin  password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
	@echo "https://localhost:8080  (Ctrl-C to stop)"
	kubectl -n argocd port-forward svc/argocd-server 8080:443
