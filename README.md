# dep-dlm-deployment

GitOps deployment of the DEP DLM data orchestration layer (Rucio server and
daemons, FTS, OPA) for RI-SCALE partners. Each RI runs its own instance, with
its own cluster, secrets store and upgrade pace. Patterns are validated in
[dep-dlm-testbed](https://github.com/RI-SCALE/dep-dlm-testbed) first and then
promoted here (see `PROMOTION.md`).

## Layout

| Path | What |
|---|---|
| `charts/dep-dlm/` | Thin umbrella over the testbed's charts (`file://` into `vendor/`) plus secrets, ConfigMaps, DB bootstrap, optional Gateway |
| `charts/dep-dlm/files/` | Symlinks into the testbed submodule (patches, scripts, configs), as in the testbed's own chart |
| `vendor/` | Submodules: `dep-dlm-testbed` and `rucio-helm-charts`, pinned to the validated commits |
| `environments/<ri>/<stage>/` | `env.yaml` (namespace, pinned `baseRevision`, ESO) and `values.yaml` (overrides only) |
| `argocd/root.yaml.tmpl` | External Secrets plus an ApplicationSet for one environment |
| `scripts/` | `bootstrap.sh` |
| `.devcontainer/` | kubectl, Helm, yq; checks out the submodules |

`<ri>` is `eiscat`, `enes`, `euro-bioimaging`, `bbmri` or `reference`;
`<stage>` is `staging` or `production`. Environments are added when there is
something real to deploy. `reference/staging` runs on the testbed's GCP
infrastructure.

## Secrets stores

| `secretStore.provider` | Use |
|---|---|
| `gcpsm` | GCP Secret Manager, Workload Identity (public cloud) |
| `vault` | Vault, Kubernetes auth (on premise) |

## Order of a sync

| Wave | Resources |
|---|---|
| -3 | `ClusterSecretStore` |
| -2 | ExternalSecrets `dep-dlm-certs`, `dep-dlm-config`; ConfigMaps |
| -1 | `rucio-bootstrap-db` Job (Sync hook) |
| 0 | rucio-server, rucio-daemons, FTS, OPA, observability |
| PostSync | `opa-init` Job (pushes authz.rego and ODRL data) |

## Getting started

```bash
git clone --recurse-submodules https://github.com/RI-SCALE/dep-dlm-deployment.git
make lint                                                         # builds the subcharts from vendor/, renders every environment
make bootstrap ENV=reference/staging ARGS=--install-argocd       # from that cluster's kubectl context
```

## First sync

The dep-dlm Application might fail its first attempts until External Secrets
(CRDs and webhook) is up, typically with `no endpoints available for service
"<eso>-webhook"`. This is expected: the sync retries with backoff (30 s up to
5 min) and converges in a few minutes. Watch it with:

```bash
kubectl -n argocd get applications -w
kubectl -n <namespace> get externalsecret,jobs,pods,gateway,httproute
```

If ESO is Healthy but the Application is still waiting in backoff, force a
refresh instead of waiting:

```bash
kubectl -n argocd annotate application dep-dlm-<ri>-<stage> \
  argocd.argoproj.io/refresh=hard --overwrite
```

`kubectl -n argocd get application dep-dlm-<ri>-<stage> -o yaml` shows the
last sync result under `status.operationState` if it does not converge.

## Promoting a testbed commit

The submodule commits are the pin: the patches, scripts, OPA policies and
subcharts all come from them, so they can never drift apart.

```bash
make sync TESTBED_REF=<validated sha> [RUCIO_REF=<sha>]
git diff --submodule=diff -- vendor/   # what is being promoted
git add vendor charts/dep-dlm/Chart.lock PROMOTION.md && git commit
```

Argo CD checks out submodules and builds `file://` dependencies itself, so
nothing generated is committed besides `Chart.lock`.

## Adding an environment

1. Copy `environments/reference/staging/` to `environments/<ri>/<stage>/`.
2. Set namespace, ESO, secrets store, remote secret keys, DB host and, on GKE,
   the Gateway.
3. Seed the store with the keys listed in `PROMOTION.md`.
4. `make bootstrap ENV=<ri>/<stage>` on that cluster.
