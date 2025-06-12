"""CRM Sync Service entry point."""

import uvicornLFLFfrom .crm_sync import appLFLFif __name__ == "__main__":LF    uvicorn.run(app, host="0.0.0.0", port=8080)
