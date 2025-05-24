"""CRM sync service for syncing contacts to HubSpot."""
import os
from datetime import datetime, timezone

from clients.hubspot_mock_client import Client, models
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, EmailStr

app = FastAPI()
hubspot = Client(base_url=os.getenv("HUBSPOT_URL", "http://hubspot-mock:8000"))


class ContactSyncEvent(BaseModel):
    """Contact synchronization event model."""

    email: EmailStr
    source: str
    timestamp: datetime
    payload: dict = {}


@app.get("/healthz")
async def health():
    """Health check endpoint."""
    return {"status": "ok", "ts": datetime.now(tz=timezone.utc).isoformat()}


@app.post("/sync", status_code=200)
async def sync(event: ContactSyncEvent):
    """Sync contact to HubSpot."""
    contact = models.Contact(
        email=event.email,
        first_name=event.payload.get("firstName"),
        last_name=event.payload.get("lastName"),
    )
    resp = await hubspot.contacts.create_contact_async(contact)
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail="Upstream HubSpot-mock error")
    return resp.parsed
