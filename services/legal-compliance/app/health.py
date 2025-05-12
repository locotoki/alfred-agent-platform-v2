#!/usr/bin/env python3
"""
Minimal health service for legal agent.
"""
from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "legal-compliance", "version": "1.0.0"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=9002)
