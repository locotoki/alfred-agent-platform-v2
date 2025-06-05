"""Model registry service main entry point."""

import os

import uvicorn
from fastapi import FastAPI
from prometheus_client import make_asgi_app

app = FastAPI(title="Model Registry")

# Prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy", "service": "model-registry"}


@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Model Registry Service", "version": "0.1.0"}


@app.get("/models")
async def get_models():
    """Get available models."""
    return [
        {
            "id": 1,
            "name": "gpt-4",
            "display_name": "GPT-4 Turbo",
            "provider": "openai",
            "model_type": "chat",
            "description": "OpenAI's most capable model",
        },
        {
            "id": 2,
            "name": "claude-3-sonnet",
            "display_name": "Claude 3 Sonnet",
            "provider": "anthropic",
            "model_type": "chat",
            "description": "Anthropic's balanced model",
        },
    ]


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8081"))
    uvicorn.run(app, host="0.0.0.0", port=port)
