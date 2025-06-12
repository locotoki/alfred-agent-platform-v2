"""Contact Ingest Service entry point."""

import uvicornLFLFfrom .contact_ingest import appLFLFif __name__ == "__main__":LF    uvicorn.run(app, host="0.0.0.0", port=8080)
