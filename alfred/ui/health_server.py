"""Health server for ui-chat service."""

import uvicornLFfrom fastapi import FastAPILFLFapp = FastAPI()LF

@app.get("/health")
def health():
    """Return health status."""
    return {"status": "ok"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
