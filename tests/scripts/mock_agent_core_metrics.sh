#!/bin/bash
# Mock metrics endpoint for testing

echo "🚀 Starting mock metrics server on :8001..."

# Create a simple Python HTTP server that returns metrics
cat > /tmp/mock_metrics.py << 'EOF'
#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler

class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/metrics':
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            # Return p95 latency above threshold
            metrics = """# HELP rag_p95_latency_ms p95 latency in ms
# TYPE rag_p95_latency_ms gauge
rag_p95_latency_ms 350
"""
            self.wfile.write(metrics.encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8001), MetricsHandler)
    print("Mock metrics server listening on :8001")
    server.serve_forever()
EOF

python3 /tmp/mock_metrics.py
