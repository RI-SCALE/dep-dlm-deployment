# modules/networking

Plain VPC and subnet for the single-node on-premise reference, with
firewall rules that allow SSH, kube-apiserver and Vault only through IAP
(`35.235.240.0/20`) and optional public ports (none by default).
