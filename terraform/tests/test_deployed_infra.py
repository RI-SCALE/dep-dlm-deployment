"""
Post-deploy smoke tests for terraform/environments/onprem/infra.

Run with the kube-apiserver tunnel open (make onprem-smoke-test does both):
    KUBECONFIG=.kube/config-onprem pytest terraform/tests/test_deployed_infra.py -v

Everything comes from `terraform output -json`. The checks run as one-shot
pods, so they use the same network path Rucio, FTS and External Secrets
use: pod -> node IP for PostgreSQL, MySQL and Vault, and cluster DNS
(CoreDNS hosts entry) for the validation storage.
Requires: pip install pytest
"""

import json
import os
import subprocess
import time
import uuid

import pytest

TF_DIR = os.environ.get("TF_DIR", "terraform/environments/onprem/infra")
NS = os.environ.get("SMOKE_NAMESPACE", "default")
POD_TIMEOUT_S = 300
RETRY_DEADLINE_S = 300  # databases/Vault may still be coming up after first boot
RETRY_BACKOFF_S = 20

SKIP_VALIDATION_STORAGE_CHECKS = os.environ.get("SKIP_VALIDATION_STORAGE_CHECKS") == "1"


@pytest.fixture(scope="session")
def tf_outputs():
    result = subprocess.run(
        ["terraform", f"-chdir={TF_DIR}", "output", "-json"],
        capture_output=True, text=True, check=True,
    )
    return {k: v["value"] for k, v in json.loads(result.stdout).items()}


def _kubectl(*args, check=False):
    return subprocess.run(["kubectl", *args], capture_output=True, text=True, check=check)


def _run_pod_once(name, image, *cmd):
    overrides = {
        "apiVersion": "v1",
        "spec": {"containers": [{
            "name": name, "image": image, "command": list(cmd),
            "resources": {"requests": {"cpu": "50m", "memory": "64Mi"}},
        }]},
    }
    try:
        run = _kubectl("run", name, "-n", NS, f"--image={image}", "--restart=Never",
                       f"--overrides={json.dumps(overrides)}")
        assert run.returncode == 0, f"kubectl run {name} failed: {run.stderr}"
        wait = _kubectl("wait", "-n", NS, "--for=jsonpath={.status.phase}=Succeeded",
                        f"pod/{name}", f"--timeout={POD_TIMEOUT_S}s")
        logs = _kubectl("logs", name, "-n", NS).stdout
        assert wait.returncode == 0, (
            f"{name} did not succeed: {wait.stderr.strip()}\n--- logs ---\n{logs or '<empty>'}"
        )
        return logs
    finally:
        _kubectl("delete", "pod", name, "-n", NS, "--ignore-not-found", "--wait=false")


def _run_pod(base, image, *cmd):
    deadline = time.time() + RETRY_DEADLINE_S
    attempt = 0
    while True:
        attempt += 1
        try:
            return _run_pod_once(f"{base}-{uuid.uuid4().hex[:8]}", image, *cmd)
        except AssertionError as e:
            if time.time() >= deadline:
                raise AssertionError(f"{base}: still failing after {attempt} attempt(s): {e}") from e
            time.sleep(RETRY_BACKOFF_S)


def test_kubeconfig_reaches_cluster_and_node_ready():
    nodes = _kubectl("get", "nodes", "-o", "json")
    assert nodes.returncode == 0, (
        f"kubectl can't reach the cluster: is the tunnel open (make onprem-tunnel) "
        f"and KUBECONFIG=.kube/config-onprem? {nodes.stderr}"
    )
    items = json.loads(nodes.stdout)["items"]
    assert len(items) == 1, f"expected a single node, got {len(items)}"
    ready = {c["type"]: c["status"] for c in items[0]["status"]["conditions"]}["Ready"]
    assert ready == "True", "node is not Ready"


def test_rucio_database_connection(tf_outputs):
    dsn = (f"postgresql://rucio:{tf_outputs['rucio_db_password']}"
           f"@{tf_outputs['rucio_database_host']}/rucio")
    logs = _run_pod("smoke-pg", "postgres:16", "psql", dsn, "-tAc", "SELECT 1;")
    assert "1" in logs


def test_fts_database_connection(tf_outputs):
    logs = _run_pod(
        "smoke-mysql", "mysql:8.4", "mysql", "-h", tf_outputs["fts_database_host"],
        "-u", "fts", f"-p{tf_outputs['fts_db_password']}", "fts", "-e", "SELECT 1;",
    )
    assert "1" in logs


def test_vault_initialised_and_unsealed(tf_outputs):
    # /sys/health: 200 = initialised and unsealed, 501 = not initialised, 503 = sealed.
    logs = _run_pod(
        "smoke-vault", "curlimages/curl:8.11.1", "curl", "-sk", "-o", "/dev/null",
        "-w", "%{http_code}", f"{tf_outputs['vault_addr']}/v1/sys/health",
    )
    assert logs.strip() == "200", (
        f"Vault health returned {logs.strip()} (501: run make onprem-vault-init; 503: sealed)"
    )


@pytest.mark.skipif(SKIP_VALIDATION_STORAGE_CHECKS, reason="SKIP_VALIDATION_STORAGE_CHECKS=1")
@pytest.mark.parametrize("port", [8081, 8082], ids=["teapot1", "teapot2"])
def test_validation_storage_resolves_and_reachable(tf_outputs, port):
    if not tf_outputs.get("valstorage_ip"):
        pytest.skip("valstorage_ip not set")
    # Any HTTP status proves DNS (CoreDNS hosts entry), routing and TLS; 000 means no connection.
    logs = _run_pod(
        f"smoke-valstorage-{port}", "curlimages/curl:8.11.1", "curl", "-sk", "-o", "/dev/null",
        "-w", "%{http_code}", f"https://{tf_outputs['valstorage_hostname']}:{port}/",
    )
    assert logs.strip() not in ("", "000"), f"validation storage :{port} not reachable from pods"
