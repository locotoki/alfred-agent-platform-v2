"""Vector ingestion worker with CloudEvents support."""

import json
import os
import time
import uuid

from fastapi import FastAPI, Response

app = FastAPI()


@app.get("/health")
def health():
    return {"status": "ok"}

import requests
from cloudevents.http import CloudEvent
from langchain.text_splitter import RecursiveCharacterTextSplitter
from sentence_transformers import SentenceTransformer

from alfred_sdk.auth.verify import verify

MODEL = SentenceTransformer(os.getenv("EMBED_MODEL", "sentence-transformers/all-MiniLM-L6-v2"))
SPLITTER = RecursiveCharacterTextSplitter(chunk_size=512, chunk_overlap=64)


def handle_cloud_event(event: CloudEvent):
    claims = verify(event["headers"].get("authorization", "").split()[-1])
    data = json.loads(event.data)
    tenant = claims["tenant"]
    doc_id = data["id"]

    chunks = SPLITTER.split_text(data["text"])
    vectors = MODEL.encode(chunks).tolist()

    payload = {
        "tenant": tenant,
        "doc_id": doc_id,
        "ttl_days": data.get("ttl_days", 90),
        "chunks": chunks,
        "vectors": vectors,
    }
    requests.post("http://vector-db:6333/ingest", json=payload, timeout=5)
    print(f"[{tenant}] ingested {len(chunks)} chunks for {doc_id}", flush=True)
