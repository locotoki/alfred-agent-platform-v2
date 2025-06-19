#!/usr/bin/env python3
"""
Copies first N vectors from Qdrant into Postgres pgvector table.
Run with: PG_DSN=postgresql://user:pass@localhost:5432/memory python migrate_qdrant_to_pgvector.py
"""
import os, sys, requests, psycopg2, json

QDRANT = os.getenv("QDRANT_URL", "http://localhost:6333")
LIMIT  = int(os.getenv("MIGRATE_LIMIT", "1000"))
PG_DSN = os.getenv("PG_DSN", "postgresql://memory:memorypass@localhost:5432/memory")

def fetch_vectors(limit):
    resp = requests.post(f"{QDRANT}/collections/repo-docs/points/scroll",
                         json={"limit": limit, "with_vectors": True})
    resp.raise_for_status()
    return resp.json()["points"]

def upsert_pg(points):
    conn = psycopg2.connect(PG_DSN)
    cur  = conn.cursor()
    cur.execute("SET search_path TO public;")
    for p in points:
        cur.execute("INSERT INTO embeddings (id, path, sha, vec) VALUES (%s,%s,%s,%s) "
                    "ON CONFLICT (id) DO NOTHING",
                    (p["id"], p["payload"]["path"], p["payload"].get("sha",""),
                     p["vector"]))
    conn.commit()
    cur.close(); conn.close()

def main():
    points = fetch_vectors(LIMIT)
    print(f"Fetched {len(points)} vectors from Qdrant.")
    if "--dry" in sys.argv:
        return
    upsert_pg(points)
    print("Upserted into Postgres.")

if __name__ == "__main__":
    main()