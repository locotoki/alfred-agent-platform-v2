"""Slack webhook adapter with HMAC verification.

This module implements the FastAPI endpoint for Slack events and commands, including
request signature validation.
"""

import hashlib
import hmac
import json
import os
import time
from typing import Any, Dict, Optional

import structlog
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import JSONResponse
from prometheus_client import Counter
from pydantic import BaseModel

# Prometheus metrics
slack_events_total = Counter(
    "alfred_slack_events_total", "Total Slack events received", ["result", "event_type"]
)

logger = structlog.get_logger(__name__)

# Create FastAPI app
app = FastAPI(title="Alfred Slack Adapter")


class SlackRequest(BaseModel):
    """Model for Slack slash command requests"""

    token: Optional[str] = None
    team_id: str
    team_domain: str
    channel_id: str
    channel_name: str
    user_id: str
    user_name: str
    command: str
    text: str
    response_url: str
    trigger_id: str


class SlackEventWrapper(BaseModel):
    """Model for Slack event wrapper"""

    token: Optional[str] = None
    team_id: str
    api_app_id: str
    event: Dict[str, Any]
    type: str
    event_id: str
    event_time: int
    challenge: Optional[str] = None  # For URL verification


class SlackVerifier:
    """Handles Slack request signature verification"""

    def __init__(self, signing_secret: str):
        self.signing_secret = signing_secret

    def verify_signature(self, timestamp: str, body: bytes, signature: str) -> bool:
        """Verify Slack request signature.

        Args:
            timestamp: Request timestamp from headers
            body: Raw request body
            signature: Signature from headers

        Returns:
            True if signature is valid
        """
        # Check timestamp to prevent replay attacks (5 minute window)
        try:
            ts = int(timestamp)
            if abs(time.time() - ts) > 300:
                logger.warning("Slack request timestamp too old", timestamp=timestamp)
                return False
        except ValueError:
            logger.warning("Invalid timestamp format", timestamp=timestamp)
            return False

        # Create the signature base string
        sig_basestring = f"v0:{timestamp}:".encode() + body

        # Calculate expected signature
        expected_sig = (
            "v0="
            + hmac.new(self.signing_secret.encode(), sig_basestring, hashlib.sha256).hexdigest()
        )

        # Compare signatures
        return hmac.compare_digest(expected_sig, signature)


# Initialize verifier
signing_secret = os.getenv("SLACK_SIGNING_SECRET", "")
if not signing_secret:
    logger.warning("SLACK_SIGNING_SECRET not set, signature verification disabled")
    verifier = None
else:
    verifier = SlackVerifier(signing_secret)


@app.post("/slack/events")
async def handle_slack_events(request: Request) -> Response:
    """Handle Slack events and slash commands"""
    # Get headers for verification
    timestamp = request.headers.get("X-Slack-Request-Timestamp", "")
    signature = request.headers.get("X-Slack-Signature", "")

    # Get raw body for signature verification
    body = await request.body()

    # Verify signature if verifier is available
    if verifier:
        if not timestamp or not signature:
            slack_events_total.labels(result="invalid_sig", event_type="unknown").inc()
            logger.warning("Missing Slack signature headers")
            raise HTTPException(status_code=401, detail="Missing signature headers")

        if not verifier.verify_signature(timestamp, body, signature):
            slack_events_total.labels(result="invalid_sig", event_type="unknown").inc()
            logger.warning("Invalid Slack signature")
            raise HTTPException(status_code=401, detail="Invalid signature")

    # Parse body
    content_type = request.headers.get("content-type", "")

    if "application/json" in content_type:
        # Event API request
        try:
            data = json.loads(body)

            # Handle URL verification challenge
            if data.get("type") == "url_verification":
                slack_events_total.labels(result="ok", event_type="url_verification").inc()
                return JSONResponse({"challenge": data.get("challenge")})

            # Handle regular events
            event_type = data.get("event", {}).get("type", "unknown")
            slack_events_total.labels(result="ok", event_type=event_type).inc()

            logger.info("Slack event received", event_type=event_type)

            # TODO: Route to appropriate handler
            return JSONResponse({"status": "ok"})

        except json.JSONDecodeError:
            slack_events_total.labels(result="error", event_type="invalid_json").inc()
            logger.error("Invalid JSON in Slack event")
            raise HTTPException(status_code=400, detail="Invalid JSON")

    else:
        # Slash command (form-encoded)
        try:
            # Parse form data
            form_data = {}
            for line in body.decode().split("&"):
                if "=" in line:
                    key, value = line.split("=", 1)
                    form_data[key] = value

            command = form_data.get("command", "")
            text = form_data.get("text", "")

            slack_events_total.labels(result="ok", event_type=f"command_{command}").inc()

            # Handle specific commands
            if command == "/alfred":
                if text.strip().lower() == "ping":
                    return JSONResponse({"response_type": "in_channel", "text": "pong"})
                else:
                    return JSONResponse(
                        {
                            "response_type": "ephemeral",
                            "text": f"Received command: {text}",
                        }
                    )

            # Unknown command
            return JSONResponse({"response_type": "ephemeral", "text": "Unknown command"})

        except Exception as e:
            slack_events_total.labels(result="error", event_type="parse_error").inc()
            logger.error("Error parsing Slack command", error=str(e))
            raise HTTPException(status_code=400, detail="Invalid request format")


@app.get("/health")
async def health_check() -> Dict[str, str]:
    """Health check endpoint"""
    return {"status": "healthy", "service": "alfred-slack-adapter"}


@app.get("/healthz")
async def healthz() -> Dict[str, str]:
    """Health check endpoint for Kubernetes"""
    return {"status": "ok", "service": "alfred-slack-adapter", "version": "1.0.0"}


@app.get("/")
async def root() -> Dict[str, str]:
    """Root endpoint"""
    return {"service": "Alfred Slack Adapter", "version": "1.0.0"}
