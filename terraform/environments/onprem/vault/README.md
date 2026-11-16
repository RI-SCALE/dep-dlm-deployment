# environments/onprem/vault

Fills Vault on the node (`modules/vault-config`): the `certs` and `config`
entries External Secrets reads, and Kubernetes auth for it. A separate
root because the Vault provider needs a running, initialised Vault, which
only exists after `../infra` has been applied and `scripts/vault-init.sh`
has run. Reached through an IAP tunnel; `make onprem-vault-apply` handles
the tunnel and the token.
