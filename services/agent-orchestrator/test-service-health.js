// Simple test to check if our service-health module is correctly detecting the social-intel service

async function testHealthCheck() {
  console.log('Testing service health check...');

  // Endpoints to try
  const endpoints = [
    'http://localhost:9000/health/',
    'http://localhost:9000/health',
    'http://social-intel:9000/health/',
    'http://social-intel:9000/health'
  ];

  for (const endpoint of endpoints) {
    try {
      console.log(`Testing endpoint: ${endpoint}`);

      const response = await fetch(endpoint, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        signal: AbortSignal.timeout(5000)
      });

      console.log(`Response status for ${endpoint}: ${response.status}`);

      // Handle redirects
      if (response.status >= 300 && response.status < 400 && response.headers.has('location')) {
        const redirectUrl = response.headers.get('location');
        console.log(`Following redirect to: ${redirectUrl}`);

        const redirectResponse = await fetch(redirectUrl, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          signal: AbortSignal.timeout(5000)
        });

        console.log(`Redirect response status: ${redirectResponse.status}`);

        if (redirectResponse.ok) {
          const data = await redirectResponse.json();
          console.log(`Service is AVAILABLE (via redirect) at ${endpoint}`);
          console.log(`Response data:`, data);
          return true;
        }
      }

      // Check direct response
      if (response.ok) {
        const data = await response.json();
        console.log(`Service is AVAILABLE at ${endpoint}`);
        console.log(`Response data:`, data);
        return true;
      }
    } catch (error) {
      console.error(`Error testing ${endpoint}:`, error.message);
    }
  }

  console.error('All endpoints failed - service is UNAVAILABLE');
  return false;
}

// Run the test
testHealthCheck();
