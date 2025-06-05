import json
import os
import pathlib
import subprocess
import textwrap
import time

import pytest

COMPOSE = ["docker", "compose", "--profile", "core"]


def wait_healthy(timeout=180):
    t0 = time.time()
    while time.time() - t0 < timeout:
        output = subprocess.check_output(COMPOSE + ["ps", "--format", "json"]).decode().strip()
        if not output:
            time.sleep(5)
            continue

        # Parse multiple JSON objects on separate lines
        ps = []
        for line in output.split("\n"):
            if line.strip():
                ps.append(json.loads(line.strip()))

        bad = [
            s
            for s in ps
            if s["State"] != "running" or (s["Health"] != "healthy" and s["Health"] != "")
        ]
        if not bad:
            return
        time.sleep(5)
    pytest.fail(
        textwrap.dedent(
            f"""
        Services unhealthy after {timeout}s:
        {json.dumps(bad, indent=2)}
    """
        )
    )


def test_core_profile_healthy(tmp_path):
    subprocess.check_call(COMPOSE + ["up", "-d", "--pull=missing"])
    try:
        wait_healthy()
    finally:
        subprocess.call(COMPOSE + ["down", "-v"])
