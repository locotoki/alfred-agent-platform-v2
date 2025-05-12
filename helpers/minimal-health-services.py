#!/usr/bin/env python3
"""
Helper script to create minimal health endpoints for agent services.
"""

import os
import sys
import subprocess

FINANCIAL_HEALTH_APP = """
from fastapi import FastAPI
import uvicorn

health_app = FastAPI()

@health_app.get("/")
async def health_check():
    return {"status": "ok", "service": "financial-tax", "version": "1.0.0"}

if __name__ == "__main__":
    uvicorn.run(health_app, host="0.0.0.0", port=9003)
"""

LEGAL_HEALTH_APP = """
from fastapi import FastAPI
import uvicorn

health_app = FastAPI()

@health_app.get("/")
async def health_check():
    return {"status": "ok", "service": "legal-compliance", "version": "1.0.0"}

if __name__ == "__main__":
    uvicorn.run(health_app, host="0.0.0.0", port=9002)
"""

def main():
    """
    Main function to create minimal health services for agents.
    """
    print("Setting up minimal health services for agents...")
    
    # Create temporary health service files
    with open("/tmp/financial_health.py", "w") as f:
        f.write(FINANCIAL_HEALTH_APP)
    
    with open("/tmp/legal_health.py", "w") as f:
        f.write(LEGAL_HEALTH_APP)
    
    # Copy the files to the containers
    try:
        # Copy files to containers
        financial_copy = subprocess.run(
            ["docker", "cp", "/tmp/financial_health.py", "agent-financial:/app/health.py"],
            capture_output=True,
            text=True
        )
        
        if financial_copy.returncode != 0:
            print("Error copying financial health app:", financial_copy.stderr)
        else:
            print("Financial health app copied successfully")
        
        legal_copy = subprocess.run(
            ["docker", "cp", "/tmp/legal_health.py", "agent-legal:/app/health.py"],
            capture_output=True,
            text=True
        )
        
        if legal_copy.returncode != 0:
            print("Error copying legal health app:", legal_copy.stderr)
        else:
            print("Legal health app copied successfully")
        
        # Start health services in background
        financial_exec = subprocess.run(
            ["docker", "exec", "-d", "agent-financial", "python", "/app/health.py"],
            capture_output=True,
            text=True
        )
        
        if financial_exec.returncode != 0:
            print("Error starting financial health service:", financial_exec.stderr)
        else:
            print("Financial health service started")
        
        legal_exec = subprocess.run(
            ["docker", "exec", "-d", "agent-legal", "python", "/app/health.py"],
            capture_output=True,
            text=True
        )
        
        if legal_exec.returncode != 0:
            print("Error starting legal health service:", legal_exec.stderr)
        else:
            print("Legal health service started")
        
        print("\nMinimal health services setup complete.")
        print("To test, run: curl http://localhost:9003/ and curl http://localhost:9002/")
        
    except Exception as e:
        print(f"An error occurred: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    sys.exit(main())