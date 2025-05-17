/**
 * Health check module for UI Admin Service
 * Provides standardized health endpoints and metrics
 */
const express = require('express');
const http = require('http');
// Use node-fetch for making HTTP requests
let fetch;
// Handle ESM vs CommonJS difference
(async () => {
  const nodeFetch = await import('node-fetch');
  fetch = nodeFetch.default;
})();
const router = express.Router();

// Initialize metrics counters
let requestsTotal = 0;
let serviceHealth = 1; // 1 = healthy, 0 = unhealthy

// Define dependencies to check
const dependencies = {
  agentCore: process.env.ALFRED_API_URL || 'http://agent-core:8011',
  ragService: process.env.ALFRED_RAG_URL || 'http://agent-rag:8501',
  socialIntel: process.env.NEXT_PUBLIC_SOCIAL_INTEL_URL || 'http://agent-social:9000'
};

/**
 * Check if a service is available by making a GET request
 * @param {string} url - URL to check
 * @returns {Promise<boolean>} - True if service is available
 */
async function checkServiceAvailability(url) {
  try {
    const timeout = 2000; // 2 second timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);
    
    const response = await fetch(`${url}/health`, {
      signal: controller.signal,
      method: 'GET',
    });
    
    clearTimeout(timeoutId);
    return response.ok;
  } catch (error) {
    console.log(`Health check failed for ${url}: ${error.message}`);
    return false;
  }
}

/**
 * Check all dependencies and return their status
 * @returns {Promise<Object>} - Status of all dependencies
 */
async function checkDependencies() {
  const services = {};
  let hasError = false;
  
  for (const [name, url] of Object.entries(dependencies)) {
    const isAvailable = await checkServiceAvailability(url);
    services[name] = isAvailable ? 'ok' : 'error';
    if (!isAvailable) hasError = true;
  }
  
  // Update service health metric
  serviceHealth = hasError ? 0 : 1;
  
  return {
    status: hasError ? 'degraded' : 'ok',
    services
  };
}

// Health endpoint with detailed status
router.get('/health', async (req, res) => {
  requestsTotal += 1;
  
  try {
    // Check dependent services
    const healthStatus = await checkDependencies();
    
    res.json({
      status: healthStatus.status,
      version: '1.0.0',
      services: healthStatus.services
    });
  } catch (error) {
    console.error('Health check error:', error);
    res.status(500).json({
      status: 'error',
      version: '1.0.0',
      services: {}
    });
  }
});

// Simple health probe for container orchestration
router.get('/healthz', (req, res) => {
  requestsTotal += 1;
  res.json({ status: 'ok' });
});

// Prometheus metrics endpoint
router.get('/metrics', (req, res) => {
  requestsTotal += 1;
  
  // Format metrics in Prometheus text format
  const metrics = `# HELP service_health Service health status
# TYPE service_health gauge
service_health ${serviceHealth}

# HELP service_requests_total Total number of requests
# TYPE service_requests_total counter
service_requests_total ${requestsTotal}

# HELP service_info Service information
# TYPE service_info gauge
service_info{name="ui_admin",version="1.0.0"} 1
`;
  
  res.set('Content-Type', 'text/plain');
  res.send(metrics);
});

// Create a separate metrics server
function createMetricsServer(port = 9091) {
  const metricsApp = express();
  
  // Use the same metrics endpoint
  metricsApp.get('/metrics', (req, res) => {
    const metrics = `# HELP service_health Service health status
# TYPE service_health gauge
service_health ${serviceHealth}

# HELP service_requests_total Total number of requests
# TYPE service_requests_total counter
service_requests_total ${requestsTotal}

# HELP service_info Service information
# TYPE service_info gauge
service_info{name="ui_admin",version="1.0.0"} 1
`;
    
    res.set('Content-Type', 'text/plain');
    res.send(metrics);
  });
  
  // Add health endpoints to metrics server as well
  metricsApp.get('/health', async (req, res) => {
    const healthStatus = await checkDependencies();
    
    res.json({
      status: healthStatus.status,
      version: '1.0.0',
      services: healthStatus.services
    });
  });
  
  metricsApp.get('/healthz', (req, res) => {
    res.json({ status: 'ok' });
  });
  
  // Start the metrics server
  return metricsApp.listen(port, () => {
    console.log(`Metrics server listening on port ${port}`);
  });
}

module.exports = {
  router,
  createMetricsServer
};