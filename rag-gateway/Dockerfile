FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; else echo 'flask==2.2.3\nredis==4.5.4\nopenai==1.3.3\n' > requirements.txt && pip install --no-cache-dir -r requirements.txt; fi

# Copy source code
COPY . .

# Create empty src directory if it doesn't exist
RUN mkdir -p src

# Create a minimal app.py if it doesn't exist
RUN if [ ! -f src/app.py ]; then \
    echo 'import os\nimport logging\nfrom flask import Flask, request, jsonify\n\napp = Flask(__name__)\nlogging.basicConfig(level=logging.INFO)\nlogger = logging.getLogger(__name__)\n\n@app.route("/")\ndef home():\n    return "RAG Gateway is running"\n\n@app.route("/healthz")\ndef healthz():\n    return jsonify({"status": "healthy"})\n\n@app.route("/api/query", methods=["POST"])\ndef query():\n    data = request.json\n    logger.info(f"Received query: {data}")\n    return jsonify({"result": "This is a mock response from RAG Gateway"})\n\nif __name__ == "__main__":\n    port = int(os.environ.get("PORT", 8013))\n    logger.info(f"Starting RAG Gateway on port {port}")\n    logger.info(f"OpenAI API Key: {os.environ.get("OPENAI_API_KEY", "Not set")[0:5]}...")\n    app.run(host="0.0.0.0", port=port)' > src/app.py; \
    fi

EXPOSE 8013

CMD ["python", "-m", "flask", "--app", "src.app", "run", "--host=0.0.0.0", "--port=8013"]
