"""CRM Sync Service - Syncs contacts with CRM systems."""

import asyncioLFimport osLFLFimport httpxLFfrom apscheduler.schedulers.asyncio import AsyncIOSchedulerLFfrom fastapi import FastAPILFLFHUBSPOT_MOCK_URL = os.getenv("HUBSPOT_MOCK_URL", "http://hubspot-mock:8000")LFCONTACT_INGEST_URL = os.getenv("CONTACT_INGEST_URL", "http://contact-ingest:8080")

app = FastAPI(title="CRM-Sync", version="0.1.0")


async def sync_loop():
    """Periodic sync job to push contacts to CRM."""
    async with httpx.AsyncClient() as client:
        # TODO: pull new contacts from contact-ingest store/queue
        # Placeholder: ping both services
        try:
            await client.get(f"{CONTACT_INGEST_URL}/ping", timeout=5.0)
            await client.get(f"{HUBSPOT_MOCK_URL}/ping", timeout=5.0)
        except httpx.RequestError as e:
            print(f"Sync error: {e}")


scheduler = AsyncIOScheduler()
scheduler.add_job(sync_loop, "interval", seconds=30)
scheduler.start()


@app.on_event("startup")
async def _startup():
    """Keep scheduler alive on startup."""
    asyncio.create_task(asyncio.sleep(0))
