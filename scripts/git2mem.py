#!/usr/bin/env python3
import hashlib
import json
import os
import pathlib
import subprocess

import requests

QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
COLLECTION = "repo-docs"


def embed(text: str):
    # placeholder: call OpenAI or local embed model
    return [float(x) for x in range(5)]  # dummy vector


def upsert(file_path, content):
    import base64
    import json
    import uuid

    import requests

    vector = embed(content)
    payload = {
        "points": [
            {
                "id": hashlib.sha1(file_path.encode()).hexdigest(),
                "vector": vector,
                "payload": {"path": file_path, "content": content[:500]},
            }
        ]
    }
    requests.put(f"{QDRANT_URL}/collections/{COLLECTION}/points", json=payload, timeout=5)


def main():
    diff = subprocess.check_output(["git", "diff", "--name-only", "--cached"]).decode().splitlines()
    for f in diff:
        p = pathlib.Path(f)
        if p.suffix in {".md", ".py", ".yml"} and p.exists():
            upsert(str(p), p.read_text())


if __name__ == "__main__":
    main()
