"""HubSpot Mock Service entry point."""

import uvicornLFLFfrom .hubspot_mock import appLFLFif __name__ == "__main__":LF    uvicorn.run(app, host="0.0.0.0", port=8095)
