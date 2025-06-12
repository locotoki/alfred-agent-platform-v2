"""Contact ingest service with ETL background worker."""

import asyncioLFimport globLFimport jsonLFimport osLFLFimport aiofilesLFimport httpxLFfrom fastapi import FastAPILFfrom prometheus_client import Counter, start_http_serverLFfrom pydantic import BaseModelLFLFCRM_SYNC_URL = os.getenv("CRM_SYNC_URL", "http://crm-sync:8080/sync")LFDATA_DIR = os.getenv("INGEST_DIR", "/app/data")
INGEST_COUNTER = Counter("contact_ingest_total", "Processed contacts")

app = FastAPI(title="contact-ingest")


class IngestSummary(BaseModel):
    """Summary of ingested contacts."""

    processed: int


async def ingest_file(path: str, client: httpx.AsyncClient):
    """Ingest a single JSONL file."""
    async with aiofiles.open(path, "r") as fp:  # type: ignore
        async for line in fp:
            evt = json.loads(line.strip())
            await client.post(CRM_SYNC_URL, json=evt)
            INGEST_COUNTER.inc()


async def ingest_loop():
    """Background loop to process JSONL files."""
    async with httpx.AsyncClient(timeout=10) as client:
        while True:
            files = glob.glob(f"{DATA_DIR}/*.jsonl")
            for f in files:
                await ingest_file(f, client)
                os.remove(f)
            await asyncio.sleep(5)


@app.on_event("startup")
async def start_bg_tasks():
    """Start background tasks on app startup."""
    start_http_server(9105)  # Prometheus scrape port
    asyncio.create_task(ingest_loop())


@app.get("/healthz", response_model=IngestSummary)
async def health():
    """Health check endpoint."""
    return IngestSummary(processed=int(INGEST_COUNTER._value.get()))
