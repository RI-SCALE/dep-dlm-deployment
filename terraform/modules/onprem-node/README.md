# modules/onprem-node

Ubuntu VM with kubeadm (single node, Flannel, local-path), PostgreSQL,
MySQL and Vault on the host. The startup script runs on every boot:
one-time steps leave markers in `/var/lib/dep-dlm/`, database users, Vault
TLS and the unseal are refreshed each time. Log: `/var/log/dep-dlm-startup.log`.
Secrets come from Secret Manager (`<prefix>-node`, `<prefix>-vault-init`),
never instance metadata.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_address.external](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_address.internal](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_instance.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_project_iam_member.logging](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.monitoring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_secret_manager_secret.node](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.vault_init](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_member.node_reads](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_version.node](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_service_account.node](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.ci_can_use_node_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [random_password.fts_db](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.rucio_db](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_certs_dir"></a> [certs\_dir](#input\_certs\_dir) | Directory with vaultcert.pem, vaultkey.pem and rucio\_ca.pem (the testbed's certs/ after `VAULT_SAN=<internal_ip> make certs`) | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for all resources (e.g. dep-dlm-onprem) | `string` | n/a | yes |
| <a name="input_node_tag"></a> [node\_tag](#input\_node\_tag) | Network tag matching the networking module's firewall rules | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the static addresses | `string` | n/a | yes |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | CIDR of that subnet; PostgreSQL accepts connections from it | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnetwork the VM attaches to (module.networking) | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | GCP zone for the VM | `string` | n/a | yes |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | n/a | `number` | `100` | no |
| <a name="input_flannel_version"></a> [flannel\_version](#input\_flannel\_version) | Flannel release whose kube-flannel.yml is applied | `string` | `"v0.26.1"` | no |
| <a name="input_gateway_api_version"></a> [gateway\_api\_version](#input\_gateway\_api\_version) | Gateway API release whose standard CRDs are installed (Traefik implements them) | `string` | `"v1.5.1"` | no |
| <a name="input_image"></a> [image](#input\_image) | Boot image. Ubuntu LTS: a common on-premise base, unlike Container-Optimized OS. | `string` | `"ubuntu-os-cloud/ubuntu-2404-lts-amd64"` | no |
| <a name="input_internal_ip"></a> [internal\_ip](#input\_internal\_ip) | Fixed internal IP of the node. Must be inside subnet\_cidr and in VAULT\_SAN of the Vault certificate. | `string` | `"10.40.0.10"` | no |
| <a name="input_kubernetes_minor"></a> [kubernetes\_minor](#input\_kubernetes\_minor) | Kubernetes minor version for the pkgs.k8s.io apt repository (e.g. 1.36) | `string` | `"1.36"` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | kubeadm kubernetesVersion; must belong to kubernetes\_minor | `string` | `"v1.36.0"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | n/a | `map(string)` | `{}` | no |
| <a name="input_local_path_version"></a> [local\_path\_version](#input\_local\_path\_version) | rancher/local-path-provisioner release (default StorageClass) | `string` | `"v0.0.30"` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | 4 vCPU / 16 GB fits Kubernetes, Rucio, FTS, OPA, both databases and Vault | `string` | `"e2-standard-4"` | no |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | Pod network (Flannel's default). PostgreSQL accepts connections from it. | `string` | `"10.244.0.0/16"` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | n/a | `string` | `"10.96.0.0/12"` | no |
| <a name="input_terraform_ci_sa_email"></a> [terraform\_ci\_sa\_email](#input\_terraform\_ci\_sa\_email) | CI service account that creates the VM (granted serviceAccountUser on the node SA). null: local applies only. | `string` | `null` | no |
| <a name="input_valstorage_hostname"></a> [valstorage\_hostname](#input\_valstorage\_hostname) | Validation-storage hostname, added to CoreDNS (hosts block) so pods resolve it independently of the VPC's DNS. Empty: skip. | `string` | `""` | no |
| <a name="input_valstorage_ip"></a> [valstorage\_ip](#input\_valstorage\_ip) | Validation-storage IP for that CoreDNS entry | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_external_ip"></a> [external\_ip](#output\_external\_ip) | n/a |
| <a name="output_fts_db_password"></a> [fts\_db\_password](#output\_fts\_db\_password) | n/a |
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | n/a |
| <a name="output_internal_ip"></a> [internal\_ip](#output\_internal\_ip) | Node IP: Rucio/FTS database host and Vault address for the GitOps values |
| <a name="output_rucio_db_password"></a> [rucio\_db\_password](#output\_rucio\_db\_password) | n/a |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | n/a |
| <a name="output_vault_init_secret_id"></a> [vault\_init\_secret\_id](#output\_vault\_init\_secret\_id) | Secret Manager secret scripts/vault-init.sh stores the init output in |
| <a name="output_zone"></a> [zone](#output\_zone) | n/a |
<!-- END_TF_DOCS -->