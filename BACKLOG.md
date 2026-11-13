# Backlog

## Next
- [x] Deploy reference/staging on GCP staging (Argo CD sync converges)
- [ ] Run the testbed's E2E tests against reference/staging (transfers, deletion, authz)
- [ ] Pin the FTS image (`mgajekcern/test-fts:latest`) to the validated tag/digest
- [ ] Document each `dep-dlm-config` key against the testbed's
      `deploy/terraform/modules/secrets/templates/*.tftpl`

## Later
- [ ] Second reference setup: single-node Kubernetes (kubeadm or similar) on a GCP VM,
      with PostgreSQL, MySQL and Vault on the VM as well (on-premise path, `secretStore.provider: vault`)
- [ ] Replace vendor/ submodules: publish testbed subcharts to OCI, source rucio charts from
      upstream (or the fork via OCI), copy the deployed patches/scripts/configs in place via
      an allowlisted `make sync`, recording the testbed commit in PROMOTION.md
- [ ] Drop the `vendor/rucio-helm-charts` submodule once the fork's `configMounts`
      commits are upstream; use `https://rucio.github.io/helm-charts`
- [ ] Deployment diagram

## Production enablement
From the [testbed's backlog](https://github.com/RI-SCALE/dep-dlm-testbed/blob/main/BACKLOG.md):

- [ ] `dep-dlm-deployment` repository: curated Terraform and GitOps for partners, not a copy of the testbed
- [ ] Promotion process: each promoted component has a validated source commit, supported version,
      CI evidence, configuration requirements and known limitations (`PROMOTION.md`)
- [ ] Production configuration and defaults extracted from the testbed
- [ ] Deployment CI (`make lint` on PRs, with `submodules: true` on checkout)
- [ ] Upgrade and rollback procedures
- [ ] Partner runbooks for configuration (Rucio, OIDC, FTS, RSEs, certificates, WP4 token provider),
      with credentials supplied by the partner
    - [x] [01–07](https://github.com/RI-SCALE/dep-dlm-testbed/tree/main/docs/runbooks): sandbox quickstart, IdP,
          storage, validation storage, IdP profiles, secrets (Secret Manager + ESO), observability
    - [ ] Certificates (Rucio/FTS, public TLS)