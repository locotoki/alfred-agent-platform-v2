import os
import logging
from flask import Flask, request, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route("/")
def home():
    return "RAG Gateway is running"

@app.route("/healthz")
def healthz():
    return jsonify({"status": "healthy"})

@app.route("/api/query", methods=["POST"])
def query():
    data = request.json
    query_text = data.get("query", "")
    context = data.get("context", {})
    
    logger.info(f"Received query: {query_text}")
    logger.info(f"Context: {context}")
    
    # Simple mock response - in a real app, this would use OpenAI
    # With the OPENAI_API_KEY environment variable
    response = f"This is a response to: {query_text}"
    
    return jsonify({
        "result": response,
        "metadata": {
            "source": "rag-gateway",
            "model": "mock-model"
        }
    })

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8013))
    logger.info(f"Starting RAG Gateway on port {port}")
    logger.info(f"OpenAI API Key: {os.environ.get('OPENAI_API_KEY', 'Not set')[0:5]}...")
    app.run(host="0.0.0.0", port=port)