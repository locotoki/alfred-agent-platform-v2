// Simple standalone express server
const express = require('express');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');
const { router: healthRouter, createMetricsServer } = require('./health');

// Create express app
const app = express();
const server = http.createServer(app);
const port = process.env.PORT || 3000;

// Configure Socket.IO
const io = new Server(server);

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

// Health and metrics routes
app.use('/', healthRouter);

// Start metrics server
const metricsServer = createMetricsServer(9091);

// Basic APIs

app.get('/api/config', (req, res) => {
  res.json({
    apiUrl: process.env.ALFRED_API_URL || 'http://localhost:8011',
    ragUrl: process.env.ALFRED_RAG_URL || 'http://localhost:8501',
    socialIntelUrl: process.env.NEXT_PUBLIC_SOCIAL_INTEL_URL || 'http://localhost:9000',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Socket.IO connection handler
io.on('connection', (socket) => {
  console.log('Client connected');
  
  socket.on('disconnect', () => {
    console.log('Client disconnected');
  });
  
  // Example event handlers
  socket.on('agent:query', (data) => {
    console.log('Agent query received:', data);
    // Simulate response
    setTimeout(() => {
      socket.emit('agent:response', {
        id: data.id,
        response: `Processed query: ${data.query}`,
        timestamp: new Date().toISOString()
      });
    }, 1000);
  });
});

// Fallback handler - serve index.html for all other routes
app.get('*', (req, res) => {
  // Simple HTML response for the mission control dashboard
  res.send(`
    <\!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Alfred Agent Platform - Mission Control</title>
      <style>
        body {
          font-family: system-ui, -apple-system, sans-serif;
          background: #f5f5f5;
          padding: 2rem;
          line-height: 1.5;
        }
        .container {
          max-width: 800px;
          margin: 0 auto;
          background: white;
          padding: 2rem;
          border-radius: 8px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        h1 {
          color: #2563eb;
          margin-top: 0;
        }
        .status {
          display: flex;
          margin: 1rem 0;
          padding: 1rem;
          background: #f0f9ff;
          border-radius: 4px;
        }
        .status-indicator {
          width: 12px;
          height: 12px;
          border-radius: 50%;
          background: #10b981;
          margin-right: 0.5rem;
          margin-top: 5px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Alfred Agent Platform</h1>
        <h2>Mission Control Dashboard</h2>
        
        <div class="status">
          <div class="status-indicator"></div>
          <div>
            <strong>Status:</strong> System operational
          </div>
        </div>
        
        <p>This is a simplified version of the Mission Control UI.</p>
        <p>Environment: ${process.env.NODE_ENV || 'development'}</p>
        <p>Connected APIs:</p>
        <ul>
          <li>Core API: ${process.env.ALFRED_API_URL || 'http://localhost:8011'}</li>
          <li>RAG Service: ${process.env.ALFRED_RAG_URL || 'http://localhost:8501'}</li>
          <li>Social Intelligence: ${process.env.NEXT_PUBLIC_SOCIAL_INTEL_URL || 'http://localhost:9000'}</li>
        </ul>
      </div>
      
      <script>
        // Simple client-side code
        console.log('Mission Control Dashboard loaded');
      </script>
    </body>
    </html>
  `);
});

// Start server
server.listen(port, () => {
  console.log(`Server running on port ${port}`);
  console.log(`Health metrics available at http://localhost:9091/metrics`);
});
