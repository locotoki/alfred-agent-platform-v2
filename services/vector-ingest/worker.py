"""Minimal vector ingestion worker for P0 fix."""

import osLFLFimport uvicornLFfrom fastapi import FastAPILFLFapp = FastAPI()LF

@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "ok", "service": "vector-ingest", "mode": "minimal"}


@app.get("/")
def root():
    """Root endpoint."""
    return {"message": "Vector Ingest Service (minimal mode)", "health": "/health"}


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
