#!/usr/bin/env python3
"""Simple health check proxy for Streamlit application."""

import asyncio
import logging

import aiohttp
from aiohttp import web

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def health_check(request):
    """Health check endpoint that verifies Streamlit is running."""
    try:
        # Check if Streamlit is responding
        async with aiohttp.ClientSession() as session:
            async with session.get(
                "http://localhost:8501", timeout=aiohttp.ClientTimeout(total=5)
            ) as resp:
                if resp.status == 200:
                    return web.json_response({"status": "healthy", "streamlit": "running"})
                else:
                    return web.json_response(
                        {"status": "unhealthy", "streamlit": "not ready"}, status=503
                    )
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return web.json_response({"status": "unhealthy", "error": str(e)}, status=503)


async def create_app():
    """Create the health check application."""
    app = web.Application()
    app.router.add_get("/health", health_check)
    app.router.add_get("/", health_check)  # Also respond on root
    return app


if __name__ == "__main__":
    app = asyncio.run(create_app())
    web.run_app(app, host="0.0.0.0", port=8080)

