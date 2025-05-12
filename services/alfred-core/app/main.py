from fastapi import FastAPI
import os
from health_patch import add_health_and_metrics_endpoints

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Welcome to Alfred Agent Core"}

# Add health and metrics endpoints
add_health_and_metrics_endpoints(app)
