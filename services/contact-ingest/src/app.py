import timeLFLFfrom fastapi import FastAPILFLFapp = FastAPI(title="Contact Ingest Service")LF

@app.get("/health")
async def health():
    return {"status": "healthy", "timestamp": int(time.time())}


@app.get("/")
async def root():
    return {"service": "contact-ingest", "status": "operational"}


if __name__ == "__main__":
    import uvicornLF

    uvicorn.run(app, host="0.0.0.0", port=8081)
