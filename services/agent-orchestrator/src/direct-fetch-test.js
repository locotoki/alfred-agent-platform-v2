// Direct fetch test to social-intel service
// This script bypasses the service-health.ts module and directly tests connectivity

// List of endpoints to try
const endpoints = [
  'http://social-intel:9000/health/',
  'http://social-intel:9000/health',
  'http://localhost:9000/health/',
  'http://localhost:9000/health',
  'http://172.18.0.2:9000/health/',
  'http://172.18.0.2:9000/health'
];

// Test each endpoint
async function testEndpoints() {
  console.log('Testing social-intel endpoints...');

  for (const endpoint of endpoints) {
    try {
      console.log(`Testing endpoint: ${endpoint}`);
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3000);

      const response = await fetch(endpoint, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (response.ok) {
        const data = await response.json();
        console.log(`✅ Success for ${endpoint}:`, data);
      } else {
        console.log(`❌ Failed for ${endpoint} with status ${response.status}`);
      }
    } catch (error) {
      console.log(`❌ Error for ${endpoint}:`, error.message);
    }
  }

  console.log('Testing completed.');
}

// Run the test
testEndpoints();
