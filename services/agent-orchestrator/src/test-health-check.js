// Test the service-health module directly

// Directly import the individual functions from the service-health module
import { checkServiceHealth, getServiceStatus, forceCheckAllServices } from './lib/service-health.js';

async function runHealthCheck() {
  console.log('Starting direct health check test...');
  
  // Check initial state
  console.log('Initial service status:');
  const initialStatus = getServiceStatus('socialIntel');
  console.log('Status:', initialStatus);
  
  // Force a check
  console.log('Forcing a health check...');
  try {
    const result = await checkServiceHealth('socialIntel');
    console.log('Health check result:', result);
    
    // Get updated status
    const updatedStatus = getServiceStatus('socialIntel');
    console.log('Updated status:', updatedStatus);
  } catch (error) {
    console.error('Error during health check:', error);
  }
  
  console.log('Health check test completed.');
}

// Try to run the test with imports
runHealthCheck().catch(error => {
  console.error('Error running health check test:', error);
});