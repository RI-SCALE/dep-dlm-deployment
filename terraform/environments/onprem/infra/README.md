# environments/onprem/infra

The on-premise reference's infrastructure: VPC, firewall (admin access via
IAP only), `modules/onprem-node` (kubeadm single node, PostgreSQL, MySQL,
Vault) and a validation storage from the testbed's
`modules/validation-storage` (git source, pinned by `make sync`) with its
own private DNS zone and certificate secret. Its outputs feed `../vault`
and the GitOps values in `environments/reference-onprem/staging/`. See
`terraform/README.md` for the full order of steps.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 5.45.2 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_networking"></a> [networking](#module\_networking) | ../../../modules/networking | n/a |
| <a name="module_node"></a> [node](#module\_node) | ../../../modules/onprem-node | n/a |
| <a name="module_validation_storage"></a> [validation\_storage](#module\_validation\_storage) | git::https://github.com/RI-SCALE/dep-dlm-testbed.git//deploy/terraform/modules/validation-storage | a5af379b7c47d353e7b1ff30700ad26c7b5105c1 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_dns_managed_zone.internal](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone) | resource |
| [google_secret_manager_secret.valstorage_certs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_version.valstorage_certs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_certs_dir"></a> [certs\_dir](#input\_certs\_dir) | The testbed's certs/ after `make certs` with VAULT\_SAN and the validation storage's hostname in VALSTORAGE\_EXTERNAL\_SAN (absolute path) | `string` | n/a | yes |
| <a name="input_oidc_issuer"></a> [oidc\_issuer](#input\_oidc\_issuer) | External OIDC issuer Teapot/XRootD trust (same as the vault root's) | `string` | n/a | yes |
| <a name="input_oidc_issuer_name"></a> [oidc\_issuer\_name](#input\_oidc\_issuer\_name) | Short label for oidc\_issuer (egi-checkin-dev, lsaai-dev) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Testbed staging project (testbed bootstrap output project\_ids.staging) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region (testbed bootstrap output regions.staging) | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used in resource names | `string` | `"onprem"` | no |
| <a name="input_node_internal_ip"></a> [node\_internal\_ip](#input\_node\_internal\_ip) | Fixed node IP: Vault certificate SAN (VAULT\_SAN), database host and Vault address in the GitOps values | `string` | `"10.40.0.10"` | no |
| <a name="input_public_ports"></a> [public\_ports](#input\_public\_ports) | TCP ports opened to the internet on the node (e.g. ["80", "443"] once an ingress controller exposes Rucio/FTS) | `list(string)` | `[]` | no |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | n/a | `string` | `"10.40.0.0/24"` | no |
| <a name="input_teapot_audiences"></a> [teapot\_audiences](#input\_teapot\_audiences) | Audiences Teapot restricts the issuer's tokens to (LS AAI only) | `list(string)` | `[]` | no |
| <a name="input_teapot_extra_subs"></a> [teapot\_extra\_subs](#input\_teapot\_extra\_subs) | Extra subs mapped to Teapot's local user (client\_credentials sub, human subs) | `list(string)` | `[]` | no |
| <a name="input_teapot_idp_name"></a> [teapot\_idp\_name](#input\_teapot\_idp\_name) | IdP\_name\_1 in Teapot's STORAGE\_AREA\_1 (testbed staging uses egi) | `string` | `"egi"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_fts_database_host"></a> [fts\_database\_host](#output\_fts\_database\_host) | n/a |
| <a name="output_fts_db_password"></a> [fts\_db\_password](#output\_fts\_db\_password) | n/a |
| <a name="output_node_external_ip"></a> [node\_external\_ip](#output\_node\_external\_ip) | n/a |
| <a name="output_node_internal_ip"></a> [node\_internal\_ip](#output\_node\_internal\_ip) | n/a |
| <a name="output_node_name"></a> [node\_name](#output\_node\_name) | n/a |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | n/a |
| <a name="output_region"></a> [region](#output\_region) | n/a |
| <a name="output_rucio_database_host"></a> [rucio\_database\_host](#output\_rucio\_database\_host) | bootstrapDb.dbHost |
| <a name="output_rucio_db_password"></a> [rucio\_db\_password](#output\_rucio\_db\_password) | n/a |
| <a name="output_valstorage_hostname"></a> [valstorage\_hostname](#output\_valstorage\_hostname) | n/a |
| <a name="output_valstorage_instance_name"></a> [valstorage\_instance\_name](#output\_valstorage\_instance\_name) | n/a |
| <a name="output_valstorage_ip"></a> [valstorage\_ip](#output\_valstorage\_ip) | n/a |
| <a name="output_valstorage_pfn_roots"></a> [valstorage\_pfn\_roots](#output\_valstorage\_pfn\_roots) | For registering the RSEs |
| <a name="output_vault_addr"></a> [vault\_addr](#output\_vault\_addr) | secretStore.vault.server |
| <a name="output_vault_init_secret_id"></a> [vault\_init\_secret\_id](#output\_vault\_init\_secret\_id) | n/a |
| <a name="output_zone"></a> [zone](#output\_zone) | n/a |
<!-- END_TF_DOCS -->