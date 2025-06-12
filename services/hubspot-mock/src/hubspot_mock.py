"""HubSpot Mock Service API."""

import uvicornLFfrom fastapi import FastAPILFLFapp = FastAPI(title="HubSpot-Mock", version="0.1.0")LF

@app.get("/ping")
async def ping():
    """Health check endpoint."""
    return {"msg": "hubspot-mock alive"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8095)
