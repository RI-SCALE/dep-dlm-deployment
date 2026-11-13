# dep-dlm-deployment

GitOps deployment of the DEP DLM data orchestration layer (Rucio server and
daemons, FTS, OPA) for RI-SCALE partners. Each RI runs its own instance, with
its own cluster, secrets store and upgrade pace. Patterns are validated in
[dep-dlm-testbed](https://github.com/RI-SCALE/dep-dlm-testbed) first and then
promoted here (see `PROMOTION.md`).

```mermaid
flowchart LR
  subgraph repo["dep-dlm-deployment (git)"]
    direction TB
    vendor["vendor/<br/>dep-dlm-testbed @ sha<br/>rucio-helm-charts @ sha"]
    chart["charts/dep-dlm<br/>umbrella chart"]
    envs["environments/&lt;ri&gt;/&lt;stage&gt;/<br/>env.yaml + values.yaml"]
    vendor -- "file:// subcharts,<br/>files/ symlinks" --> chart
  end
  testbed["dep-dlm-testbed<br/>(validated commit)"] -- "make sync<br/>(submodule bump)" --> vendor

  subgraph cluster["one cluster per RI"]
    direction TB
    argo["Argo CD<br/>ApplicationSet"]
    eso["External Secrets"]
    ns["namespace<br/>Rucio server + daemons,<br/>FTS, OPA, observability"]
    argo --> eso
    argo --> ns
    eso -- "dep-dlm-certs,<br/>dep-dlm-config" --> ns
  end

  chart --> argo
  envs --> argo
  store[("Secret store<br/>GCP Secret Manager | Vault")] --> eso
  db[("PostgreSQL (Rucio)<br/>MySQL (FTS)")] --- ns
```

## Layout

| Path | What |
|---|---|
| `charts/dep-dlm/` | Thin umbrella over the testbed's charts (`file://` into `vendor/`) plus secrets, ConfigMaps, DB bootstrap, optional Gateway |
| `charts/dep-dlm/files/` | Symlinks into the testbed submodule (patches, scripts, configs), as in the testbed's own chart |
| `vendor/` | Submodules: `dep-dlm-testbed` and `rucio-helm-charts`, pinned to the validated commits |
| `environments/<ri>/<stage>/` | `env.yaml` (namespace, pinned `baseRevision`, ESO) and `values.yaml` (overrides only) |
| `argocd/root.yaml.tmpl` | External Secrets plus an ApplicationSet for one environment |
| `scripts/` | `bootstrap.sh` |
| `.devcontainer/` | kubectl, Helm, yq, gcloud; checks out the submodules |

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

```mermaid
flowchart LR
  w3["wave -3<br/>ClusterSecretStore"] --> w2["wave -2<br/>ExternalSecrets<br/>dep-dlm-certs, dep-dlm-config<br/>+ ConfigMaps"]
  w2 --> w1["wave -1 (Sync hook)<br/>rucio-bootstrap-db Job"]
  w1 --> w0["wave 0<br/>rucio-server, rucio-daemons,<br/>FTS, OPA, observability"]
  w0 --> post["PostSync hook<br/>opa-init Job<br/>(authz.rego + ODRL data)"]
```

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
make lint                                                    # builds the subcharts from vendor/, renders every environment
make bootstrap ENV=reference/staging ARGS=--install-argocd   # from that cluster's kubectl context
```

On GKE, get that context with
`gcloud container clusters get-credentials <cluster> --zone <zone> --project <project>`.

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

## Argo CD UI

```bash
make argocd-open   # port-forwards argocd-server to https://localhost:8080 until Ctrl-C
```

It prints the initial `admin` password (from `argocd-initial-admin-secret`).
The certificate is self-signed, so accept the browser warning. In the
devcontainer, VS Code forwards port 8080 to the host.

## Promoting a testbed commit

The submodule commits are the pin: the patches, scripts, OPA policies and
subcharts all come from them, so they can never drift apart.

```mermaid
flowchart LR
  a["Testbed commit<br/>passes CI + staging"] --> b["make sync<br/>TESTBED_REF=&lt;sha&gt;"]
  b --> c["Review<br/>git diff --submodule=diff"]
  c --> d["Commit vendor/, Chart.lock,<br/>PROMOTION.md; tag vX.Y.Z"]
  d --> e["Environments bump<br/>baseRevision to the tag"]
```

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
4. `make bootstrap ENV=<ri>/<stage> ARGS=--install-argocd` on that cluster.
