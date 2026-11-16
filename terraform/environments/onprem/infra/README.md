# environments/onprem/infra

The on-premise reference's infrastructure: VPC, firewall (admin access via
IAP only), `modules/onprem-node` (kubeadm single node, PostgreSQL, MySQL,
Vault) and a validation storage from the testbed's
`modules/validation-storage` (git source, pinned by `make sync`) with its
own private DNS zone and certificate secret. Its outputs feed `../vault`
and the GitOps values in `environments/reference-onprem/staging/`. See
`terraform/README.md` for the full order of steps.
