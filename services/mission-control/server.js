// Mission Control Server
const { createServer } = require('http');
const { parse } = require('url');
const next = require('next');

const dev = process.env.NODE_ENV !== 'production';
const hostname = process.env.HOSTNAME || 'localhost';
const port = parseInt(process.env.PORT || '3000', 10);

// Initialize Next.js app
const app = next({ dev, hostname, port });
const handle = app.getRequestHandler();

// Get API URL from environment or use default
const apiUrl = process.env.ALFRED_API_URL || 'http://localhost:8011';
const ragUrl = process.env.ALFRED_RAG_URL || 'http://localhost:8501';
const socialIntelUrl = process.env.NEXT_PUBLIC_SOCIAL_INTEL_URL || 'http://localhost:9000';

// Configuration object
const config = {
  apiUrl,
  ragUrl,
  socialIntelUrl
};

// Log server startup information
console.log(`Starting Mission Control server in ${dev ? 'development' : 'production'} mode`);
console.log(`API URL: ${apiUrl}`);
console.log(`RAG URL: ${ragUrl}`);
console.log(`Social Intel URL: ${socialIntelUrl}`);

app.prepare().then(() => {
  createServer(async (req, res) => {
    try {
      // Parse request URL
      const parsedUrl = parse(req.url, true);

      // Health check endpoint
      if (parsedUrl.pathname === '/health') {
        res.statusCode = 200;
        res.setHeader('Content-Type', 'application/json');
        return res.end(JSON.stringify({ status: 'ok' }));
      }

      // Server configuration endpoint
      if (parsedUrl.pathname === '/api/config') {
        res.statusCode = 200;
        res.setHeader('Content-Type', 'application/json');
        return res.end(JSON.stringify(config));
      }

      // Handle Next.js requests
      await handle(req, res, parsedUrl);
    } catch (err) {
      console.error('Error handling request:', err);
      res.statusCode = 500;
      res.end('Internal Server Error');
    }
  }).listen(port, (err) => {
    if (err) throw err;
    console.log(`> Ready on http://${hostname}:${port}`);
  });
});