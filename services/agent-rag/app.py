from fastapi import FastAPI, Request, HTTPException
from alfred_sdk.auth.verify import verify
from cloudevents.http import CloudEvent, to_structured
import uuid, time, requests, json

app = FastAPI()

@app.middleware("http")
async def _auth(req: Request, call_next):
    if req.url.path == "/health":
        return await call_next(req)
    try:
        auth_header = req.headers.get("authorization", "")
        if not auth_header.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Missing Bearer token")
        token = auth_header.split(" ")[-1]
        verify(token)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))
    return await call_next(req)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/query")
def query(req: dict):
    # TODO: replace with real vector lookup
    hits = [{"chunk_id": "demo", "text": "stub", "score": 0.42}]
    ce = CloudEvent(
        {
            "type": "rag.query.v1",
            "source": "agent-rag",
            "id": str(uuid.uuid4()),
            "time": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "tenant": req.get("tenant_id", "demo"),
        },
        {"id": req.get("id", "demo"), "hits": hits},
    )
    headers, body = to_structured(ce)
    # publish to pubsub-emulator (stubbed HTTP endpoint)
    try:
        requests.post("http://pubsub-emulator:8681/publish", headers=headers, data=body, timeout=2)
    except Exception as e:
        print("publish stub: ", e, flush=True)
    return {"hits": hits}
