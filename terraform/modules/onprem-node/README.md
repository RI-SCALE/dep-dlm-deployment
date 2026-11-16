# modules/onprem-node

One Ubuntu VM shaped like a partner site:

| Layer | What | Where |
|---|---|---|
| Kubernetes | kubeadm single node (control plane untainted), containerd, Flannel, local-path StorageClass | in the VM |
| Rucio DB | PostgreSQL (Ubuntu package), `rucio` role and database | VM, outside Kubernetes |
| FTS DB | MySQL (Ubuntu package), `fts` user and database | VM, outside Kubernetes |
| Secret store | Vault server, file storage, TLS with a certificate from the testbed CA | VM, outside Kubernetes |

The startup script (`templates/startup-script.sh.tftpl`) runs on every
boot; finished steps leave markers in `/var/lib/dep-dlm/`, and the database
users and Vault TLS files are refreshed each time. Log:
`/var/log/dep-dlm-startup.log` (or `sudo journalctl -u google-startup-scripts`).

Secrets come from Secret Manager, read with the VM's service account:
`<prefix>-node` (Vault certificate, CA, database passwords) and
`<prefix>-vault-init` (filled by `scripts/vault-init.sh`, used to unseal
Vault after a reboot).

The startup script adds the validation storage's hostname to CoreDNS
(`hosts` block), so pods resolve it whichever DNS the node uses.

Nothing administrative is public: SSH, kube-apiserver (6443) and Vault
(8200) are reachable only through IAP tunnels.
