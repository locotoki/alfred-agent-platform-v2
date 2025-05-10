/**
 * Simple Next.js development server
 * This script starts a Next.js development server on the specified port
 */

const { createServer } = require('http');
const { parse } = require('url');
const next = require('next');

// Set the port
const port = 3007;
const dev = true;
const app = next({ dev });
const handle = app.getRequestHandler();

app.prepare().then(() => {
  createServer((req, res) => {
    const parsedUrl = parse(req.url, true);
    handle(req, res, parsedUrl);
  }).listen(port, (err) => {
    if (err) throw err;
    console.log(`> Ready on http://localhost:${port}`);
  });
});