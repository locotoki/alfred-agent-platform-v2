#!/bin/sh
# Simple health server script that works with sh

PORT=${1:-8080}

echo "Starting health server on port $PORT..."

# Create a simple Python health server inline
python -c "
import http.server
import socketserver
import json

class HealthHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'healthy'}).encode())
        else:
            super().do_GET()

    def log_message(self, format, *args):
        if '/health' not in args[0]:
            super().log_message(format, *args)

with socketserver.TCPServer(('', $PORT), HealthHandler) as httpd:
    httpd.serve_forever()
"
