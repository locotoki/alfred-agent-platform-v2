"""Contact Ingest Service entry point."""

import uvicorn

from .contact_ingest import app

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)