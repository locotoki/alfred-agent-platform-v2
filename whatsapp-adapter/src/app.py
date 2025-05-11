import os
import logging
from flask import Flask, request, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route("/")
def home():
    return "WhatsApp Adapter is running"

@app.route("/healthz")
def healthz():
    return jsonify({"status": "healthy"})

@app.route("/api/webhook", methods=["POST"])
def webhook():
    data = request.json
    logger.info(f"Received webhook: {data}")
    
    # Simple acknowledgement response
    return jsonify({"status": "success"})

@app.route("/api/send", methods=["POST"])
def send_message():
    data = request.json
    to = data.get("to")
    message = data.get("message")
    
    logger.info(f"Sending message to {to}: {message}")
    
    # This would use WhatsApp API in a real implementation
    # Using WHATSAPP_API_TOKEN and WHATSAPP_PHONE_NUMBER_ID
    
    return jsonify({
        "status": "sent",
        "message_id": "mock-message-id"
    })

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8014))
    logger.info(f"Starting WhatsApp Adapter on port {port}")
    token_preview = os.environ.get("WHATSAPP_API_TOKEN", "Not set")
    token_preview = token_preview[0:5] + "..." if len(token_preview) > 5 else token_preview
    logger.info(f"WhatsApp API Token: {token_preview}")
    app.run(host="0.0.0.0", port=port)