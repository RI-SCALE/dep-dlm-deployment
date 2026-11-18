"""
DEP DLM GitOps Deployment View — reference-onprem/staging (single-node reference)

A partner-style site simulated on one GCE VM: kubeadm (Flannel, local-path)
runs Rucio, FTS and OPA; PostgreSQL, MySQL and Vault run on the same host,
outside Kubernetes. External Secrets reads Vault through Kubernetes auth.
Traefik (DaemonSet, hostPort 80) implements the Gateway API for rucio.*;
FTS is reached in-cluster. Admin access (SSH, kube-apiserver, Vault) only
through IAP. The validation storage VM and its private DNS zone come from
the testbed's Terraform module.

Edges carry no labels (Graphviz misplaces edge labels):
  solid = request/control, dashed = config (GitOps, secrets, certs, policy, DNS),
  dotted = admin access (IAP), bold = data (bytes).

Regenerate: make diagrams  (writes generated/reference_onprem_staging.png)
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.gcp.compute import ComputeEngine
from diagrams.gcp.network import DNS
from diagrams.gcp.security import SecretManager, IAP
from diagrams.k8s.compute import Deployment
from diagrams.k8s.network import Ingress
from diagrams.onprem.database import PostgreSQL, MySQL
from diagrams.onprem.security import Vault
from diagrams.onprem.gitops import Argocd
from diagrams.onprem.network import Traefik
from diagrams.onprem.client import Users
from diagrams.generic.network import Firewall
from diagrams.generic.storage import Storage
from diagrams.programming.flowchart import Document

graph_attr = {
    "fontsize": "22",
    "bgcolor": "white",
    "pad": "0.6",
    "splines": "polyline",
    "nodesep": "0.7",
    "ranksep": "0.9",
}
node_attr = {"fontsize": "11"}
cluster_attr = {"margin": "30"}

with Diagram(
    "DEP DLM — reference-onprem/staging (single node, kubeadm)",
    filename="generated/reference_onprem_staging",
    outformat="png",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    node_attr=node_attr,
):
    users = Users("Clients\n(rucio.*)")
    admin = Users("Operators / CI")
    idp_ext = Firewall("External AAI\n(EGI / LS AAI)")
    policies = Document("ODRL policy\nrepository (WP4)")
    source_rses = Storage("Source RSEs")
    dest_rses = Storage("Destination RSEs")

    with Cluster("GCP project (testbed staging): own VPC dep-dlm-onprem"):
        iap = IAP("IAP\n(SSH, :6443, :8200)")
        sm = SecretManager("Secret Manager\n(node secrets,\nvault-init, certs)")
        dns = DNS("Cloud DNS\n(private zone:\nrucio, valstorage)")

        with Cluster("GCE VM: dep-dlm-onprem-node (Ubuntu, public :80 only)"):
            pg = PostgreSQL("PostgreSQL\n(Rucio)")
            my = MySQL("MySQL\n(FTS)")
            vault = Vault("Vault\n(TLS, K8s auth)")

            with Cluster("kubeadm single node (Flannel, local-path)"):
                argocd = Argocd("Argo CD")
                traefik = Traefik("Traefik\n(hostPort 80)")

                with Cluster("namespace: dep-dlm-staging", graph_attr=cluster_attr):
                    gateway = Ingress("Gateway +\nHTTPRoute")
                    eso = Deployment("External Secrets\nOperator")
                    rucio_server = Deployment("Rucio Server")
                    rucio_daemons = Deployment("Rucio Daemons")
                    fts = Deployment("FTS3")
                    opa = Deployment("OPA")

        with Cluster("GCE VM: dep-dlm-onprem-validation-storage", graph_attr=cluster_attr):
            valstorage = ComputeEngine("xrd3/xrd4 (XRootD)\nteapot1/teapot2 (WebDAV)")

    # GitOps and secrets
    argocd >> Edge(style="dashed") >> rucio_server
    eso >> Edge(style="dashed") >> vault
    sm >> Edge(style="dashed") >> vault
    sm >> Edge(style="dashed") >> valstorage
    opa >> Edge(style="dashed") >> policies
    dns >> Edge(style="dashed") >> valstorage

    # Requests
    users >> traefik >> gateway >> rucio_server
    rucio_server >> pg
    rucio_server >> idp_ext
    rucio_server >> opa
    rucio_daemons >> fts
    fts >> my

    # Transfers
    fts >> valstorage
    fts >> source_rses
    fts >> dest_rses
    source_rses >> Edge(style="bold") >> dest_rses

    # Admin access
    admin >> Edge(style="dotted") >> iap
    iap >> Edge(style="dotted") >> argocd
    iap >> Edge(style="dotted") >> vault