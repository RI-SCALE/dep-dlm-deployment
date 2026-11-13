SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

CHART   := charts/dep-dlm
ENV     ?= reference/staging
TESTBED := vendor/dep-dlm-testbed
RUCIO   := vendor/rucio-helm-charts

.PHONY: help
help: ## Show targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: init
init: ## Check out the pinned submodules
	git submodule update --init

.PHONY: sync
sync: ## Pin the testbed (and rucio charts) to a validated commit: TESTBED_REF=<sha> [RUCIO_REF=<sha>]
	@[[ -n "$(TESTBED_REF)" ]] || { echo "usage: make sync TESTBED_REF=<sha> [RUCIO_REF=<sha>]" >&2; exit 2; }
	git -C $(TESTBED) fetch -q origin && git -C $(TESTBED) checkout -q $(TESTBED_REF)
	@if [[ -n "$(RUCIO_REF)" ]]; then git -C $(RUCIO) fetch -q origin && git -C $(RUCIO) checkout -q $(RUCIO_REF); fi
	$(MAKE) deps
	@git submodule status
	@echo "Review 'git diff --submodule=diff', update PROMOTION.md, then commit vendor/ and Chart.lock."

.PHONY: deps
deps: ## Build the subcharts from vendor/ (refreshes Chart.lock; charts/ stays untracked)
	helm dependency update $(CHART)

.PHONY: lint
lint: deps ## Lint and render every environment
	@for env in environments/*/*/; do \
	  echo "==> $$env"; \
	  helm lint $(CHART) -f $$env/values.yaml >/dev/null || exit 1; \
	  helm template dep-dlm $(CHART) -f $$env/values.yaml >/dev/null || exit 1; \
	done

.PHONY: template
template: ## Render one environment (ENV=<ri>/<stage>)
	helm template dep-dlm $(CHART) -f environments/$(ENV)/values.yaml

.PHONY: bootstrap
bootstrap: ## Bootstrap ENV on the current kubectl context
	scripts/bootstrap.sh $(ENV)
