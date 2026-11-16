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

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_vault"></a> [vault](#provider\_vault) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [vault_auth_backend.kubernetes](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/auth_backend) | resource |
| [vault_kubernetes_auth_backend_config.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_config) | resource |
| [vault_kubernetes_auth_backend_role.eso](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_kv_secret_v2.certs](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2) | resource |
| [vault_kv_secret_v2.config](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2) | resource |
| [vault_mount.kv](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) | resource |
| [vault_policy.read](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bootstrap_userpass_pwd"></a> [bootstrap\_userpass\_pwd](#input\_bootstrap\_userpass\_pwd) | n/a | `string` | n/a | yes |
| <a name="input_certs_dir"></a> [certs\_dir](#input\_certs\_dir) | The testbed's certs/ directory (make certs): host certificate, CA, signing policy | `string` | n/a | yes |
| <a name="input_eso_service_account_name"></a> [eso\_service\_account\_name](#input\_eso\_service\_account\_name) | External Secrets service account (env.yaml eso.name) | `string` | n/a | yes |
| <a name="input_eso_service_account_namespace"></a> [eso\_service\_account\_namespace](#input\_eso\_service\_account\_namespace) | Its namespace (env.yaml eso.namespace) | `string` | n/a | yes |
| <a name="input_fts_db_host"></a> [fts\_db\_host](#input\_fts\_db\_host) | n/a | `string` | n/a | yes |
| <a name="input_fts_db_password"></a> [fts\_db\_password](#input\_fts\_db\_password) | n/a | `string` | n/a | yes |
| <a name="input_kubernetes_ca_cert"></a> [kubernetes\_ca\_cert](#input\_kubernetes\_ca\_cert) | PEM of the cluster CA (/etc/kubernetes/pki/ca.crt) | `string` | n/a | yes |
| <a name="input_kubernetes_host"></a> [kubernetes\_host](#input\_kubernetes\_host) | kube-apiserver URL as Vault reaches it (the node's internal IP) | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Path prefix of the two KV entries (<prefix>/certs, <prefix>/config) and the policy name | `string` | n/a | yes |
| <a name="input_oidc_client_id"></a> [oidc\_client\_id](#input\_oidc\_client\_id) | n/a | `string` | n/a | yes |
| <a name="input_oidc_client_secret"></a> [oidc\_client\_secret](#input\_oidc\_client\_secret) | n/a | `string` | n/a | yes |
| <a name="input_oidc_issuer"></a> [oidc\_issuer](#input\_oidc\_issuer) | n/a | `string` | n/a | yes |
| <a name="input_rucio_db_host"></a> [rucio\_db\_host](#input\_rucio\_db\_host) | n/a | `string` | n/a | yes |
| <a name="input_rucio_db_password"></a> [rucio\_db\_password](#input\_rucio\_db\_password) | n/a | `string` | n/a | yes |
| <a name="input_scope_profile"></a> [scope\_profile](#input\_scope\_profile) | IdP profile under profiles/ (egi-dev, ls-aai-dev) | `string` | n/a | yes |
| <a name="input_userpass_password"></a> [userpass\_password](#input\_userpass\_password) | n/a | `string` | n/a | yes |
| <a name="input_kubernetes_auth_path"></a> [kubernetes\_auth\_path](#input\_kubernetes\_auth\_path) | Kubernetes auth mount (secretStore.vault.kubernetesAuth.mountPath) | `string` | `"kubernetes"` | no |
| <a name="input_kv_mount"></a> [kv\_mount](#input\_kv\_mount) | KV v2 mount (secretStore.vault.path in the GitOps values) | `string` | `"secret"` | no |
| <a name="input_oidc_client_account"></a> [oidc\_client\_account](#input\_oidc\_client\_account) | n/a | `string` | `"randomaccount"` | no |
| <a name="input_oidc_expected_audience"></a> [oidc\_expected\_audience](#input\_oidc\_expected\_audience) | n/a | `string` | `"https://fts.example.org/"` | no |
| <a name="input_oidc_expected_scope"></a> [oidc\_expected\_scope](#input\_oidc\_expected\_scope) | n/a | `string` | `"openid offline_access storage.read:/ storage.modify:/"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Kubernetes auth role (secretStore.vault.kubernetesAuth.role) | `string` | `"dep-dlm"` | no |
| <a name="input_rucio_host"></a> [rucio\_host](#input\_rucio\_host) | Base URL the Rucio client/auth host point at | `string` | `"http://rucio-server"` | no |
| <a name="input_site_name"></a> [site\_name](#input\_site\_name) | n/a | `string` | `"DOCKER"` | no |
| <a name="input_storage_ip"></a> [storage\_ip](#input\_storage\_ip) | Validation-storage IP (valstorage-ip key); null: omitted | `string` | `null` | no |
| <a name="input_token_mode"></a> [token\_mode](#input\_token\_mode) | n/a | `string` | `"managed"` | no |
| <a name="input_userpass_account"></a> [userpass\_account](#input\_userpass\_account) | n/a | `string` | `"ddmlab"` | no |
| <a name="input_userpass_username"></a> [userpass\_username](#input\_userpass\_username) | n/a | `string` | `"ddmlab"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_certs_key"></a> [certs\_key](#output\_certs\_key) | secrets.certsKey in the GitOps values |
| <a name="output_config_key"></a> [config\_key](#output\_config\_key) | secrets.configKey in the GitOps values |
| <a name="output_kubernetes_auth_path"></a> [kubernetes\_auth\_path](#output\_kubernetes\_auth\_path) | n/a |
| <a name="output_kv_mount"></a> [kv\_mount](#output\_kv\_mount) | n/a |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | n/a |
<!-- END_TF_DOCS -->