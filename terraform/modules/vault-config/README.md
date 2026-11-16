# modules/vault-config

Vault counterpart of the testbed's `modules/secrets`:

- KV v2 mount (`secret`) with `<prefix>/config` (server.cfg, alembic.ini,
  idpsecrets.json, fts3config, fts3restconfig, docker-entrypoint.sh, DSNs,
  ...) and `<prefix>/certs` (host certificate, CA, signing policy), the same
  keys `dep-dlm-config` and `dep-dlm-certs` get on GCP.
- Kubernetes auth, a read policy for `<prefix>/*` and a role bound to the
  External Secrets service account.

`templates/` and `profiles/` are copied from the testbed by `make sync`
(same commit as `charts/dep-dlm/files/`); don't edit them here.
