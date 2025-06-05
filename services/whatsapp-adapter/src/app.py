from fastapi import FastAPI, Request
import os, sys, json

ENABLED = os.getenv("WHATSAPP_ENABLED", "false").lower() == "true"
app = FastAPI(title="WhatsApp Adapter (Sandbox)")

@app.on_event("startup")
async def guard():
    if not ENABLED:
        print("WhatsApp adapter disabled (WHATSAPP_ENABLED=false)", file=sys.stderr)

@app.get("/health")
def health():
    return {"status": "ok", "enabled": ENABLED}

@app.post("/webhook")
async def webhook(req: Request):
    if not ENABLED:
        return {"error": "adapter disabled"}
    payload = await req.json()
    # TODO: forward to agent-core (Kafka/gRPC). Stub prints for now.
    print("⇢ inbound WA payload:", json.dumps(payload)[:500], file=sys.stderr)
    return {"received": True}