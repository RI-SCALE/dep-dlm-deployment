# Promotion record

Every release of `charts/dep-dlm` records what it was promoted from. A
release is a git tag (`vX.Y.Z`); environments pin it as `baseRevision`.

## Unreleased

| Item | Value |
|---|---|
| Testbed source | dep-dlm-testbed `a5af379b7c47d353e7b1ff30700ad26c7b5105c1` (`files/`; fts, opa, observability charts) |
| Rucio charts | mgajek-cern/helm-charts `e69bb891a7045d64ec0fb72198ce7e502fed83a3` |
| Subcharts | `git+https` refs pinned to those commits, vendored in `charts/dep-dlm/charts/` (`Chart.lock`) |
| Images | rucio-server/-daemons `release-41.2.1`, OPA `1.8.0-static`, FTS `mgajekcern/test-fts:latest` (to pin) |
| CI evidence | _link to the testbed run(s) the source commit passed_ |
| Validated on | _reference/staging: link to e2e and user-flow results_ |

### Configuration requirements
- `dep-dlm-config` keys: `server.cfg`, `alembic.ini`, `idpsecrets.json`,
  `fts3config`, `fts3restconfig`, `docker-entrypoint.sh`; with observability,
  `rucio-db-dsn`, `fts-db-dsn`.
- `dep-dlm-certs` keys: `hostcert.pem`, `hostkey.pem`, `hostcert_with_key.pem`,
  `rucio_ca.pem`, `tls_ca_bundle.pem`, `5fca1cb1.0`, `5fca1cb1.signing_policy`.
- External PostgreSQL (Rucio) and MySQL (FTS); an OIDC IdP profile as in the
  testbed's runbook 05.

### Known limitations
- Upstream Rucio and FTS are patched (testbed `patches/`); see the testbed's
  `docs/patches.md`.
- Gateway is HTTP only; public TLS follows the testbed's runbook 8.
- FTS route on the Gateway not yet ported (`environments/reference/staging/values.yaml`).
