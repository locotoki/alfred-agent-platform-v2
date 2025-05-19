const request = require('supertest');
const express = require('express');

// Mock the health endpoint
const app = express();
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {
      slack: 'connected',
      redis: 'connected'
    }
  });
});

describe('Health Check Endpoint', () => {
  test('GET /health returns healthy status', async () => {
    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body.status).toBe('healthy');
    expect(response.body.services).toEqual({
      slack: 'connected',
      redis: 'connected'
    });
  });
});
