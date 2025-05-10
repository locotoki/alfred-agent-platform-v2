// Simple health check test
import fetch from 'node-fetch';

async function testHealthCheck() {
  const endpoints = [
    'http://social-intel:9000/health/',
    'http://social-intel:9000/health',
    'http://localhost:9000/health/',
    'http://localhost:9000/health',
    'http://172.18.0.2:9000/health/',
    'http://172.18.0.2:9000/health'
  ];
  
  console.log('[Health] Testing all health check endpoints...');
  
  for (const endpoint of endpoints) {
    try {
      console.log(`[Health] Checking health at ${endpoint}`);
      
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);
      
      const response = await fetch(endpoint, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        signal: controller.signal
      });
      
      clearTimeout(timeoutId);
      
      console.log(`[Health] Response status for ${endpoint}: ${response.status}`);
      
      if (response.ok) {
        const responseData = await response.json();
        console.log(`[Health] Response data:`, responseData);
        console.log(`[Health] Service social-intel available: true`);
      }
    } catch (error) {
      console.error(`[Health] Error checking health at ${endpoint}:`, error.message);
    }
  }
}

testHealthCheck();