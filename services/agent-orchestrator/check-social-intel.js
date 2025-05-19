// Direct check of Social Intelligence service health
import fetch from 'node-fetch';

async function checkHealth() {
  const socialIntelUrl = 'http://localhost:9000/health/';

  try {
    console.log(`Checking Social Intelligence health at ${socialIntelUrl}...`);
    const response = await fetch(socialIntelUrl);

    if (response.ok) {
      const data = await response.json();
      console.log('Health check response:', data);
      console.log('Social Intelligence service is available.');
    } else {
      console.error(`Health check failed with status: ${response.status}`);
      console.log('Social Intelligence service is unavailable.');
    }
  } catch (error) {
    console.error('Error checking Social Intelligence health:', error.message);
    console.log('Social Intelligence service is unavailable due to connection error.');
  }
}

// Run the check
checkHealth();
