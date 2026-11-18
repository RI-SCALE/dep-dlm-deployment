# environments/onprem/vault

Vault contents (`modules/vault-config`), applied through an IAP tunnel by
`make onprem-vault-apply` after `../infra` and `make onprem-vault-init`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | ~> 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_vault_config"></a> [vault\_config](#module\_vault\_config) | ../../../modules/vault-config | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_remote_state.infra](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bootstrap_userpass_pwd"></a> [bootstrap\_userpass\_pwd](#input\_bootstrap\_userpass\_pwd) | n/a | `string` | n/a | yes |
| <a name="input_certs_dir"></a> [certs\_dir](#input\_certs\_dir) | The testbed's certs/ (absolute path): CA for the provider, host certificate for the certs entry | `string` | n/a | yes |
| <a name="input_kubernetes_ca_cert_file"></a> [kubernetes\_ca\_cert\_file](#input\_kubernetes\_ca\_cert\_file) | Cluster CA written by scripts/fetch-kubeconfig.sh | `string` | n/a | yes |
| <a name="input_oidc_client_id"></a> [oidc\_client\_id](#input\_oidc\_client\_id) | n/a | `string` | n/a | yes |
| <a name="input_oidc_client_secret"></a> [oidc\_client\_secret](#input\_oidc\_client\_secret) | n/a | `string` | n/a | yes |
| <a name="input_oidc_issuer"></a> [oidc\_issuer](#input\_oidc\_issuer) | n/a | `string` | n/a | yes |
| <a name="input_scope_profile"></a> [scope\_profile](#input\_scope\_profile) | egi-dev \| ls-aai-dev | `string` | n/a | yes |
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | Testbed staging state bucket (testbed bootstrap output state\_buckets.staging), to read ../infra's outputs | `string` | n/a | yes |
| <a name="input_userpass_password"></a> [userpass\_password](#input\_userpass\_password) | n/a | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | `"onprem"` | no |
| <a name="input_eso_service_account_name"></a> [eso\_service\_account\_name](#input\_eso\_service\_account\_name) | Must match environments/reference-onprem/staging/env.yaml eso.name | `string` | `"external-secrets"` | no |
| <a name="input_eso_service_account_namespace"></a> [eso\_service\_account\_namespace](#input\_eso\_service\_account\_namespace) | Must match env.yaml eso.namespace | `string` | `"external-secrets"` | no |
| <a name="input_oidc_expected_audience"></a> [oidc\_expected\_audience](#input\_oidc\_expected\_audience) | n/a | `string` | `"https://fts.example.org/"` | no |
| <a name="input_oidc_expected_scope"></a> [oidc\_expected\_scope](#input\_oidc\_expected\_scope) | n/a | `string` | `"openid offline_access storage.read:/ storage.modify:/"` | no |
| <a name="input_token_mode"></a> [token\_mode](#input\_token\_mode) | n/a | `string` | `"managed"` | no |
| <a name="input_vault_addr"></a> [vault\_addr](#input\_vault\_addr) | Vault as reached through the IAP tunnel | `string` | `"https://localhost:18200"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ca_bundle"></a> [ca\_bundle](#output\_ca\_bundle) | secretStore.vault.caBundle (base64 of the testbed CA) |
| <a name="output_certs_key"></a> [certs\_key](#output\_certs\_key) | secrets.certsKey |
| <a name="output_config_key"></a> [config\_key](#output\_config\_key) | secrets.configKey |
| <a name="output_kubernetes_auth"></a> [kubernetes\_auth](#output\_kubernetes\_auth) | secretStore.vault.kubernetesAuth |
| <a name="output_vault_server"></a> [vault\_server](#output\_vault\_server) | secretStore.vault.server |
<!-- END_TF_DOCS -->
