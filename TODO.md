- Review terraform content of the GCP VM setup simulating on premise single nodes including all needed installed software
- Setup CI similar to dep-dlm-testbed once working locally running commands in terminal. We need to install terraform in the devcontainer as a precondition first

Known gaps (also listed in the README), worth adding to BACKLOG.md:

markdown
- [ ] On-premise reference: expose Rucio/FTS (ingress controller + `public_ports`) so the testbed E2E tests can target it
- [ ] Make the chart's CA file names (`5fca1cb1.*`) configurable, so each site can use its own CA
- [ ] Vault on the on-premise reference: more than one unseal key, no root token in Secret Manager

---

Conventional commit:

feat(terraform): add the on-premise reference infrastructure

Add terraform/ in the testbed's layout: a bootstrap for this repo's own
project and CI identity, and an onprem environment with two roots.
infra creates a VM running a single-node kubeadm cluster with
PostgreSQL, MySQL and Vault (TLS from the testbed CA) next to it, all
admin access through IAP. vault fills Vault with the same certs and
config entries the testbed renders into Secret Manager, plus Kubernetes
auth for External Secrets.

Add the reference-onprem/staging GitOps environment
(secretStore.provider: vault), bind the ESO service account to
system:auth-delegator for Vault, copy the secret templates and IdP
profiles in `make sync`, and add Terraform and the onprem make targets
to the devcontainer and Makefile.