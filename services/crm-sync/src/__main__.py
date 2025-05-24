"""CRM Sync Service entry point."""

import uvicorn

from .crm_sync import app

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)