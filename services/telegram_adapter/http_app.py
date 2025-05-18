"""Telegram webhook adapter using FastAPI.
"""

import os

from fastapi import FastAPI, Header, HTTPException, Request
from prometheus_client import Counter

# TODO: import IntentRouter

# Initialize FastAPI app
app = FastAPI()

# Prometheus counter for Telegram events, labeled by verification status
telegram_events_total = Counter(
    "telegram_events_total",
    "Total number of Telegram events",
    ["verified"],
)


@app.get("/telegram/webhook")
async def handshake(challenge: str):
    """
    Challenge-response handshake endpoint.
    """
    # TODO: implement challenge-response handshake logic
    return challenge


@app.post("/telegram/webhook")
async def telegram_webhook(
    request: Request,
    x_telegram_bot_api_secret_token: str = Header(None),
):
    """
    Telegram webhook endpoint for incoming messages.
    """
    # Verify Telegram secret token
    secret_token = os.getenv("TELEGRAM_BOT_API_SECRET_TOKEN")
    verified = x_telegram_bot_api_secret_token == secret_token
    telegram_events_total.labels(verified=str(verified).lower()).inc()
    if not verified:
        raise HTTPException(status_code=401, detail="Invalid signature")

    # TODO: forward payload to IntentRouter.route()
    payload = await request.json()
    return {"status": "ok"}
