# Alfred‑Home : Minimal WhatsApp AI Assistant for (v2025‑05‑05b)

# Alfred‑Home : Minimal WhatsApp AI Assistant for (v2025‑05‑05b)

*Lean starter kit for a single‑tenant family instance on **Fly.io + Redis Streams + Supabase**. Use it as a quick bootstrap before the full production stack.*

---

## 1 · Essential Components (≤ 1 day)

### A. WhatsApp Business Basics

```
1. Business Manager already verified (Digital Native Ventures → tenant *home*).
2. Add WhatsApp product to Meta App **Alfred**.
3. Reserve phone number (test or production).
4. Generate sandbox token or system‑user long‑lived token.
5. Set webhook URL → https://<fly‑app>.fly.dev/webhook.

```

### B. Minimal Backend Service (FastAPI · Redis Streams)

```python
# main.py – 120 lines, no ORMs
import os, hmac, hashlib, json, asyncio
from typing import Dict
from fastapi import FastAPI, Request, HTTPException
import httpx, openai
from redis.asyncio import Redis

app = FastAPI()

# ── Env / secrets (injected via `fly secrets set …`) ───────────────────────────
REDIS_URL   = os.getenv("REDIS_URL", "redis://default:redispw@localhost:6379/0")
WH_TOKEN    = os.getenv("WHATSAPP_TOKEN")
PHONE_ID    = os.getenv("WHATSAPP_PHONE_ID")
VERIFY_TOKEN= os.getenv("VERIFY_TOKEN", "alfred_token")
APP_SECRET  = os.getenv("META_APP_SECRET")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

openai.api_key = OPENAI_API_KEY
redis = Redis.from_url(REDIS_URL, decode_responses=True)
INSTANCE = "home"  # hard‑coded for single‑tenant

# ── In‑memory personal snapshot (swap for Supabase later) ──────────────────────
PERSONAL: Dict[str, Dict] = {
    "shopping_list": [],
    "preferences": {},
}

# ── WhatsApp Webhook ───────────────────────────────────────────────────────────
@app.get("/webhook")
async def verify(mode: str, challenge: str, token: str):
    if mode == "subscribe" and token == VERIFY_TOKEN:
        return int(challenge)
    raise HTTPException(403)

@app.post("/webhook")
async def inbound(req: Request):
    raw = await req.body()
    sig = req.headers.get("X-Hub-Signature-256", "")[7:]
    if not hmac.compare_digest(sig, hmac.new(APP_SECRET.encode(), raw, hashlib.sha256).hexdigest()):
        raise HTTPException(403)
    await redis.xadd("alfred-ingest", {"payload": raw, "instance": INSTANCE})
    return {"status": "ok"}

# ── Simple Worker coroutine (run with `python main.py worker`) ─────────────────
async def worker():
    stream = "alfred-ingest"
    last_id = "0-0"
    async for msg in redis.xread({stream: last_id}, block=0):
        _stream, entries = msg
        for entry_id, fields in entries:
            event = json.loads(fields["payload"])
            await handle_event(event)
            last_id = entry_id

after_send_headers = {"Authorization": f"Bearer {WH_TOKEN}", "Content-Type": "application/json"}

async def handle_event(event):
    value = event["entry"][0]["changes"][0]["value"]
    if "messages" not in value:
        return
    msg = value["messages"][0]
    from_no = msg["from"]
    text = msg["text"]["body"]
    reply = await chat_with_ai(text, from_no)
    payload = {
        "messaging_product": "whatsapp",
        "to": from_no,
        "type": "text",
        "text": {"body": reply},
    }
    async with httpx.AsyncClient() as client:
        await client.post(f"https://graph.facebook.com/v18.0/{PHONE_ID}/messages",
                          headers=after_send_headers, json=payload)

async def chat_with_ai(message: str, user: str) -> str:
    prompt = (
        "You are Alfred, a helpful family assistant.\n" +
        f"Current shopping list: {PERSONAL['shopping_list']}\n" +
        f"User message: {message}\nRespond helpfully."
    )
    resp = await openai.ChatCompletion.acreate(
        model="gpt-4o-mini",  # cheaper model for home
        messages=[{"role": "system", "content": prompt}]
    )
    return resp.choices[0].message.content

if __name__ == "__main__":
    import sys, uvicorn, asyncio
    if len(sys.argv) > 1 and sys.argv[1] == "worker":
        asyncio.run(worker())
    else:
        uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

```

### C. Docker & Fly Launch

```
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

```

```yaml
version: "3.9"
services:
  redis:
    image: redis:7
    command: ["redis-server", "--save", "", "--appendonly", "no"]
    ports: ["6379:6379"]
  alfred:
    build: .
    environment:
      - REDIS_URL=redis://redis:6379/0
      - WHATSAPP_TOKEN=${WHATSAPP_TOKEN}
      - WHATSAPP_PHONE_ID=${WHATSAPP_PHONE_ID}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - META_APP_SECRET=${META_APP_SECRET}
    ports: ["8000:8000"]
    depends_on: [redis]

```

For Fly:

```bash
fly launch --name alfred-home --region mad --vm-size shared-cpu-1x --memory 256
fly secrets set WHATSAPP_TOKEN=… WHATSAPP_PHONE_ID=… OPENAI_API_KEY=… META_APP_SECRET=…
fly deploy

```

---

## 2 · Personal Data Integration (pick one)

| Option | Good For | Notes |
| --- | --- | --- |
| **A. Supabase quick‑start** | Lists, reminders, pgvector embeddings | `supabase link` → use PostgREST; 30‑day hot/90‑day cold policy |
| **B. SQLite local** | Rapid hack nights | Volume‑mounted `alfred.db`; migrate later |
| **C. Upstash Redis JSON** | Ephemeral session data | `redis.json()` handy; TTL = 30 d |

---

## 3 · Deployment Checklist

1. **Meta:** add webhook callback & subscribe `messages` event.
2. **Fly:** `fly deploy`, ensure port 8080->8000 mapping in `fly.toml`.
3. **Test:** send `hello` from phone → expect AI reply.

---

## 4 · Minimal Feature Set

- Natural‑language replies (GPT‑4o‑mini).
- `/add milk` and `/list` commands (shopping).
- 1‑click Fly redeploy via GitHub Action.

---

## 5 · Next Five Enhancements

1. Swap PERSONAL dict → Supabase table + pgvector.
2. Background job for morning briefing (CRON in Fly).
3. Typing indicators & emoji reactions via WhatsApp API.
4. Per‑user memory window stored in Redis stream `alfred‑memory:{user}`.
5. Cost telemetry to Grafana (OpenAI spend per day).

---

### Time Investment

| Task | Hours |
| --- | --- |
| Meta & phone setup | 2 |
| FastAPI + Redis glue | 3 |
| Fly deploy & secrets | 1 |
| Manual smoke test | 1 |
| **Total** | **7 h** |

---

*End of document*
