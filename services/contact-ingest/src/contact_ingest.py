"""Contact Ingest Service API."""

from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Contact-Ingest", version="0.1.0")


class Contact(BaseModel):
    """Contact model for lead capture."""

    email: str
    first_name: str | None = None
    last_name: str | None = None


@app.post("/ingest")
async def ingest(contact: Contact):
    """Accept contact for processing."""
    # TODO: forward to hubspot-mock or queue
    return {"status": "accepted", "contact": contact}