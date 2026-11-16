# terraform

Infrastructure for the **on-premise reference**: one GCE VM shaped like a
partner site, a single-node kubeadm cluster with PostgreSQL (Rucio), MySQL
(FTS) and Vault outside Kubernetes, plus a validation storage. It exercises
what GKE staging doesn't: databases and secret store outside the cluster,
`secretStore.provider: vault`, no GKE Gateway.

It runs in the **testbed's staging project**, which `dep-dlm-testbed` owns
(project, APIs, state bucket, CI identity, OS Login, IAP). This repo adds
only `dep-dlm-onprem-*` resources in their own VPC (`10.40.0.0/24`) and
state prefixes (`onprem/infra`, `onprem/vault`).

```
terraform/
├── environments/onprem/
│   ├── infra/          # VPC, node, validation storage (testbed module, pinned by make sync)
│   └── vault/          # Vault contents; separate root, needs an initialised Vault
├── modules/
│   ├── networking/     # VPC; SSH, 6443, 8200 via IAP only
│   ├── onprem-node/    # VM + startup script: kubeadm, PostgreSQL, MySQL, Vault
│   └── vault-config/   # certs/config KV entries, Kubernetes auth for External Secrets
├── scripts/            # IAP tunnel, kubeconfig, vault-init, env resolution
└── tests/              # pod-based smoke test
```

## Prerequisites

- The testbed's bootstrap applied with `iap.googleapis.com`, and you in its
  `os_login_admins`. For CI from this repo, `additional_github_repos` must
  list `RI-SCALE/dep-dlm-deployment`.
- `gcloud auth login` and `gcloud auth application-default login`.
- The testbed's staging project, region and state bucket, exported (or read
  from an initialised `TESTBED_BOOTSTRAP`, default
  `../dep-dlm-testbed/deploy/terraform/bootstrap`):

```bash
export GCP_PROJECT_ID=<project_ids.staging> GCP_REGION=<regions.staging> \
       TF_STATE_BUCKET=<state_buckets.staging>
```

## Certificates

Everything trusts the testbed CA, so the chart's `5fca1cb1.*` names stay
valid. Generate once, before the first plan, with the testbed's
`generate-certs.sh` (apply `docs/testbed-generate-certs-vault-san.patch`
there until it supports `VAULT_SAN`):

```bash
(cd ../dep-dlm-testbed && \
  VALSTORAGE_EXTERNAL_SAN="valstorage.dep-dlm-onprem.example.com,valstorage.dep-dlm-staging.example.com" \
  VAULT_SAN=10.40.0.10 make certs)
```

Pods reach the validation storage by hostname, so no IP is needed up front.
Regenerating means re-applying both roots; the vault root's `ca_bundle`
output must match `caBundle` in `environments/reference-onprem/staging/values.yaml`.

## First deployment

```bash
# 1. Infra (the node's startup script then needs ~10 min)
make tf-init TF_ENV=onprem/infra && make tf-plan TF_ENV=onprem/infra && make tf-apply TF_ENV=onprem/infra

# 2. Cluster access, Vault, smoke test (each opens its own IAP tunnel)
make onprem-kubeconfig     # waits for kubeadm; .kube/config-onprem, .kube/onprem-ca.crt
make onprem-vault-init     # init + unseal; init response -> Secret Manager
make onprem-smoke-test     # node, PostgreSQL, MySQL, Vault, validation storage from pods

# 3. Vault contents
make tf-init TF_ENV=onprem/vault
make onprem-vault-apply SCOPE_PROFILE=egi-dev OIDC_CLIENT_SECRET=...

# 4. GitOps (tunnel open, see below)
KUBECONFIG=.kube/config-onprem make bootstrap ENV=reference-onprem/staging ARGS=--install-argocd
```

With the default `node_internal_ip` (`10.40.0.10`), the GitOps values
(Vault server, CA bundle, keys, database host) are already filled in.

## Using the cluster

Nothing administrative is public: SSH, kube-apiserver and Vault are
reachable only through IAP. The kubeconfig points at the tunnel's local end
and grants cluster-admin; it stays in the gitignored `.kube/`.

```bash
make onprem-tunnel                            # terminal 1, keep open
export KUBECONFIG=$PWD/.kube/config-onprem    # terminal 2
kubectl get nodes && make argocd-open
```

The startup log: `gcloud compute ssh dep-dlm-onprem-node --zone <zone>
--tunnel-through-iap --command 'sudo tail -f /var/log/dep-dlm-startup.log'`.

## Reference-only shortcuts

- Vault: one unseal key, file storage, init response (incl. root token) in
  Secret Manager so the VM unseals itself after a reboot.
- The testbed CA's private key is in the testbed repo.
- This repo's CI acts as the testbed's `dep-dlm-terraform-ci` in staging.
- Rucio and FTS have no ingress yet, so the testbed's E2E tests can't target
  this environment (`public_ports` opens the firewall once one exists).

## Teardown

`make tf-destroy TF_ENV=onprem/vault` (optional), then
`make tf-destroy TF_ENV=onprem/infra`, and `rm -rf .kube/`. That removes only
this repo's resources; the project, bucket and IAM belong to the testbed.