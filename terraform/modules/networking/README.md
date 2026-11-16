# modules/networking

VPC and subnet with SSH, kube-apiserver and Vault reachable only through
IAP (`35.235.240.0/20`), optional public ports.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_firewall.iap_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.public_ingress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_network.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for all networking resource names (e.g. dep-dlm-onprem) | `string` | n/a | yes |
| <a name="input_node_tag"></a> [node\_tag](#input\_node\_tag) | Network tag the firewall rules target | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the subnet | `string` | n/a | yes |
| <a name="input_public_ports"></a> [public\_ports](#input\_public\_ports) | TCP ports opened to public\_source\_ranges (empty: none) | `list(string)` | `[]` | no |
| <a name="input_public_source_ranges"></a> [public\_source\_ranges](#input\_public\_source\_ranges) | Source ranges for public\_ports | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | Primary CIDR of the node subnet. Must contain the node's fixed internal IP. | `string` | `"10.40.0.0/24"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | n/a |
| <a name="output_subnet_cidr"></a> [subnet\_cidr](#output\_subnet\_cidr) | n/a |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | n/a |
<!-- END_TF_DOCS -->