# Backlog

## Next
- [ ] Pin the FTS image (`mgajekcern/test-fts:latest`) to the validated tag/digest
- [ ] Document each `dep-dlm-config` key against the testbed's
      `deploy/terraform/modules/secrets/templates/*.tftpl`

## Production enablement

- [ ] Upgrade and rollback procedures
- [ ] OPA loads its policy at startup (today only via the PostSync hook)
- [ ] Configurable CA file names (`5fca1cb1.*`) per site
- [ ] Vault: more than one unseal key, no root token in Secret Manager