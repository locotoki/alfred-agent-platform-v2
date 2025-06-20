import asyncio
import json
import os
from datetime import datetime
from typing import Dict, List

import openai
import psycopg2
import redis
from fastapi import Body, FastAPI, Request
from fastapi.responses import JSONResponse, PlainTextResponse, StreamingResponse
from nats.aio.client import Client as NATS

# Simple prompt builder function
def build_prompt(system_snips, user_query):
    context = "\n".join(system_snips) if system_snips else ""
    return f"Context: {context}\n\nUser Query: {user_query}"

PG_DSN = os.getenv("PG_DSN")
NATS_URL = os.getenv("NATS_URL", "nats://nats:4222")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
openai.api_key = OPENAI_API_KEY

app = FastAPI()

# Health route
@app.get("/healthz")
def health():
    try:
        psycopg2.connect(PG_DSN).close()
        return {"status": "ok"}
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

# SSE chat completion
@app.post("/architect/complete")
async def complete(req: Request):
    body = await req.json()
    user_query = body.get("query", "")
    system_snips = body.get("context", [])
    prompt = build_prompt(system_snips, user_query)
    async def event_generator():
        resp = openai.ChatCompletion.create(
            model="gpt-4o-mini",
            messages=[{"role": "system", "content": prompt}],
            stream=True,
        )
        for chunk in resp:
            yield f"data: {json.dumps(chunk['choices'][0]['delta'])}\n\n"
    return StreamingResponse(event_generator(), media_type="text/event-stream")

# PRD validator endpoint
@app.post("/prd/validate")
async def validate(prd: dict):
    required = ["id", "title", "acceptance_tasks"]
    missing = [k for k in required if k not in prd]
    return {"valid": not missing, "missing": missing}

# ---------------------------------------------------------------------------
# Chat Export Endpoint (Markdown)
# ---------------------------------------------------------------------------

def _messages_to_markdown(msgs: List[Dict]) -> str:
    md = ["# Architect Chat Export\n"]
    for m in msgs:
        role = m.get("role", "user").title()
        content = m.get("content", "")
        md.append(f"## {role}\n\n{content}\n")
    return "\n".join(md)

@app.post("/architect/export", response_class=PlainTextResponse)
async def export_chat(body: Dict = Body(...)):
    """
    Expects:
      {
        "thread_id": "abc123",
        "messages": [
          {"role": "user", "content": "Hi"},
          {"role": "assistant", "content": "Hello"}
        ]
      }
    Returns a Markdown document for download.
    """
    msgs = body.get("messages", [])
    return _messages_to_markdown(msgs)

# Planner trigger coroutine (optional)
async def planner_listener():
    nc = NATS()
    await nc.connect(NATS_URL)
    sub = await nc.subscribe("prd.merged")
    async for msg in sub.messages:
        print("Planner trigger", msg.data.decode())


asyncio.create_task(planner_listener())