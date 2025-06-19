import asyncio
import datetime
import json
import os
import sys

import psycopg2
from nats.aio.client import Client as NATS
from openai import OpenAI

MAX_CHARS = 12000
OPENAI_KEY = os.getenv("OPENAI_API_KEY")
client = OpenAI(api_key=OPENAI_KEY)
PG_DSN = os.getenv("PG_DSN", "postgresql://memory:memorypass@vector-pg:5432/memory")


def summarise(text):
    prompt = (
        "Summarise the following project events in concise bullet points "
        "(≤200 tokens, focus on decisions, outcomes, incidents):\n\n" + text[:MAX_CHARS]
    )
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
    )
    return response.choices[0].message.content.strip()


def store_summary(ts, text):
    conn = psycopg2.connect(PG_DSN)
    cur = conn.cursor()
    cur.execute(
        "CREATE TABLE IF NOT EXISTS summaries (ts TIMESTAMP PRIMARY KEY, text TEXT);"
    )
    cur.execute(
        "INSERT INTO summaries (ts, text) VALUES (%s, %s) ON CONFLICT DO NOTHING",
        (ts, text),
    )
    conn.commit()
    cur.close()
    conn.close()


async def consume():
    nc = NATS()
    await nc.connect(os.getenv("NATS_URL", "nats://nats:4222"))
    js = nc.jetstream()

    # Ensure consumer exists
    await js.add_consumer(
        stream="EVENTS",
        config={"durable_name": "summariser", "ack_policy": "explicit"},
    )

    sub = await js.pull_subscribe("events.*", durable="summariser")
    while True:
        msgs = await sub.fetch(500, timeout=5)
        if not msgs:
            await asyncio.sleep(55)
            continue
        texts = []
        for m in msgs:
            evt = json.loads(m.data.decode())
            ts = evt["ts"]
            texts.append(f"{ts} {evt['type']} {evt.get('payload','')}")
            await m.ack()
        summary = summarise("\n".join(texts))
        store_summary(datetime.datetime.utcnow(), summary)
        print("↳ Stored hourly summary of", len(texts), "events")


if __name__ == "__main__":
    # Handle dry-run mode
    if "--dry-run" in sys.argv:
        print("Running in dry-run mode for 60 seconds...")
        import time
        time.sleep(60)
        print("Dry-run completed")
    else:
        asyncio.run(consume())