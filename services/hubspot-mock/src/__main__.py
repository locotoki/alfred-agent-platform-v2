"""HubSpot Mock Service entry point."""

import uvicorn

from .hubspot_mock import app

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8095)
