// Standalone simple server for Mission Control
const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const port = process.env.PORT || 3000;

console.log('Starting Mission Control standalone server...');
console.log(`PORT: ${port}`);
console.log(`NODE_ENV: ${process.env.NODE_ENV}`);
console.log(`API URL: ${process.env.ALFRED_API_URL}`);
console.log(`RAG URL: ${process.env.ALFRED_RAG_URL}`);
console.log(`Social Intel URL: ${process.env.NEXT_PUBLIC_SOCIAL_INTEL_URL}`);

// Serve static files from the public directory
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Serve a simple HTML page
app.get('*', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Mission Control</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          margin: 0;
          padding: 0;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          height: 100vh;
          background-color: #f5f5f5;
        }
        .container {
          text-align: center;
          padding: 2rem;
          background-color: white;
          border-radius: 8px;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
          max-width: 800px;
          width: 100%;
        }
        h1 {
          color: #333;
        }
        p {
          color: #666;
          margin-bottom: 1.5rem;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Alfred Agent Platform - Mission Control</h1>
        <p>The Mission Control dashboard is currently in maintenance mode.</p>
        <p>Please check back later or contact the administrator for more information.</p>
        <p>The system health check is working correctly.</p>
      </div>
    </body>
    </html>
  `);
});

app.listen(port, () => {
  console.log(`Mission Control server running at http://localhost:${port}`);
});