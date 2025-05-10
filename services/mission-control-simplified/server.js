/**
 * Simplified Mission Control Server
 * 
 * Express server that provides API endpoints and serves the Mission Control UI.
 * Integrates with the Social Intelligence Agent for workflow execution.
 */

const express = require('express');
const path = require('path');
const cors = require('cors');
const { 
  callNicheScout, 
  callSeedToBlueprint, 
  checkSocialIntelStatus, 
  getAgentStatuses 
} = require('./integrate-with-social-intel');

// Load environment variables
require('dotenv').config();

// Create Express app
const app = express();
// Try port 3007 first, then fall back to 3010 if 3007 is not available
const PREFERRED_PORT = process.env.PORT || 3007;
const FALLBACK_PORT = 3010;
let PORT = PREFERRED_PORT;

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json());

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// API routes with real integration
app.get('/api/health', async (req, res) => {
  console.log('Health check requested');
  const socialIntelOnline = await checkSocialIntelStatus();
  res.json({ 
    status: 'healthy', 
    uptime: process.uptime(),
    services: {
      'social-intelligence': socialIntelOnline ? 'online' : 'offline'
    },
    timestamp: new Date().toISOString()
  });
});

app.get('/api/agents/status', async (req, res) => {
  console.log('Agent status requested');
  try {
    const statuses = await getAgentStatuses();
    res.json(statuses);
  } catch (error) {
    console.error('Error getting agent statuses:', error.message);
    res.status(500).json({ 
      error: 'Failed to get agent statuses',
      message: error.message
    });
  }
});

app.post('/api/workflows/niche-scout', async (req, res) => {
  console.log('Niche-Scout workflow requested with params:', JSON.stringify(req.body));
  try {
    const result = await callNicheScout(req.body);
    res.json(result);
  } catch (error) {
    console.error('Error in Niche-Scout workflow:', error.message);
    res.status(500).json({ 
      error: 'Failed to execute Niche-Scout workflow',
      message: error.message
    });
  }
});

app.post('/api/workflows/seed-to-blueprint', async (req, res) => {
  console.log('Seed-to-Blueprint workflow requested with params:', JSON.stringify(req.body));
  try {
    const result = await callSeedToBlueprint(req.body);
    res.json(result);
  } catch (error) {
    console.error('Error in Seed-to-Blueprint workflow:', error.message);
    res.status(500).json({ 
      error: 'Failed to execute Seed-to-Blueprint workflow',
      message: error.message
    });
  }
});

// Route handling for HTML pages
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/workflows/niche-scout', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'niche-scout.html'));
});

app.get('/workflows/seed-to-blueprint', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'seed-to-blueprint.html'));
});

// Default route for SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start the server with fallback logic
const server = app.listen(PORT, () => {
  console.log(`
  ======================================================
   Mission Control server running on port ${PORT}
  ======================================================
  
  API Endpoints:
  - Health check: http://localhost:${PORT}/api/health
  - Agent status: http://localhost:${PORT}/api/agents/status
  - Niche-Scout: http://localhost:${PORT}/api/workflows/niche-scout (POST)
  - Seed-to-Blueprint: http://localhost:${PORT}/api/workflows/seed-to-blueprint (POST)
  
  UI Pages:
  - Dashboard: http://localhost:${PORT}/
  - Niche-Scout workflow: http://localhost:${PORT}/workflows/niche-scout
  - Seed-to-Blueprint workflow: http://localhost:${PORT}/workflows/seed-to-blueprint
  
  Integration with Social Intelligence Agent is ${process.env.ENABLE_MOCK_FALLBACK !== 'false' ? 'enabled with fallback' : 'enabled (strict mode)'}
  ======================================================
  `);
}).on('error', (err) => {
  if (err.code === 'EADDRINUSE' && PORT === PREFERRED_PORT) {
    console.log(`Port ${PREFERRED_PORT} is already in use, trying fallback port ${FALLBACK_PORT}`);
    PORT = FALLBACK_PORT;
    
    // Try the fallback port
    server.close();
    app.listen(PORT, () => {
      console.log(`
      ======================================================
       Mission Control server running on fallback port ${PORT}
      ======================================================
      
      API Endpoints:
      - Health check: http://localhost:${PORT}/api/health
      - Agent status: http://localhost:${PORT}/api/agents/status
      - Niche-Scout: http://localhost:${PORT}/api/workflows/niche-scout (POST)
      - Seed-to-Blueprint: http://localhost:${PORT}/api/workflows/seed-to-blueprint (POST)
      
      UI Pages:
      - Dashboard: http://localhost:${PORT}/
      - Niche-Scout workflow: http://localhost:${PORT}/workflows/niche-scout
      - Seed-to-Blueprint workflow: http://localhost:${PORT}/workflows/seed-to-blueprint
      
      Integration with Social Intelligence Agent is ${process.env.ENABLE_MOCK_FALLBACK !== 'false' ? 'enabled with fallback' : 'enabled (strict mode)'}
      
      NOTE: Using fallback port because primary port ${PREFERRED_PORT} is in use
      ======================================================
      `);
    }).on('error', (err) => {
      console.error(`Failed to start server on both ports ${PREFERRED_PORT} and ${FALLBACK_PORT}`);
      console.error(err);
      process.exit(1);
    });
  } else {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
});