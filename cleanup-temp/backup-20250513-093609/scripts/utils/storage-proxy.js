/**
 * Simple Proxy for Supabase Storage API
 * 
 * This is a basic implementation that provides the minimal functionality
 * required for the Alfred Agent Platform to work without the actual
 * storage-api service being up and running.
 */

const express = require('express');
const app = express();
const port = 5000;

// Enable JSON body parsing
app.use(express.json());

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/', (req, res) => {
  res.json({ 
    name: 'storage-proxy',
    version: '1.0.0',
    status: 'running',
    message: 'This is a simple proxy for the Supabase Storage API'
  });
});

// Minimal bucket endpoints
app.get('/bucket', (req, res) => {
  res.json([{ 
    id: 'default', 
    name: 'default', 
    public: false,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }]);
});

app.post('/bucket', (req, res) => {
  res.status(201).json({ 
    id: req.body.id || 'custom-bucket',
    name: req.body.name || 'Custom Bucket',
    public: req.body.public || false,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  });
});

// Handle any other routes with a stub response
app.all('*', (req, res) => {
  console.log(`Unhandled ${req.method} request to ${req.originalUrl}`);
  res.json({ 
    message: 'Storage proxy stub response',
    method: req.method,
    path: req.originalUrl,
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(port, () => {
  console.log(`Storage proxy listening at http://localhost:${port}`);
});

console.log('Storage proxy startup complete');