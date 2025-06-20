import datetime
import os

import psycopg2
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

PG_DSN = os.getenv("PG_DSN", "postgresql://memory:memorypass@vector-pg:5432/memory")
app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


def fetch_costs(days=30):
    conn = psycopg2.connect(PG_DSN)
    cur = conn.cursor()
    cur.execute(
        """CREATE TABLE IF NOT EXISTS costs_daily (
                     date DATE PRIMARY KEY,
                     llm_usd NUMERIC,
                     ci_minutes NUMERIC)"""
    )
    cur.execute(
        "SELECT date, llm_usd, ci_minutes FROM costs_daily " "WHERE date >= %s ORDER BY date",
        (datetime.date.today() - datetime.timedelta(days=days),),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [
        {"date": str(r[0]), "llm_usd": float(r[1] or 0), "ci_minutes": float(r[2] or 0)}
        for r in rows
    ]


@app.get("/costs")
def costs():
    return fetch_costs()
