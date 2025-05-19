// Debug health check behavior
// Use dynamic import to work around module issues
async function run() {
  try {
    // Try different import paths
    let serviceHealth;
    try {
      serviceHealth = await import('./lib/service-health.js');
    } catch (e) {
      try {
        serviceHealth = await import('./lib/service-health.ts');
      } catch (e2) {
        try {
          serviceHealth = await import('./lib/service-health');
        } catch (e3) {
          console.error('Could not import service-health module:', e3.message);
          return;
        }
      }
    }

        const { checkServiceHealth, getServiceStatus, forceCheckAllServices } = serviceHealth;

    console.log('Starting health check debug...');

    // Get current status
    const initialStatus = getServiceStatus('socialIntel');
    console.log('Initial status:', JSON.stringify(initialStatus, null, 2));

    // Force a health check
    console.log('Forcing health check...');
    forceCheckAllServices();

    // Check result after a delay
    await new Promise(resolve => setTimeout(resolve, 5000));

    const afterStatus = getServiceStatus('socialIntel');
    console.log('Status after forced check:', JSON.stringify(afterStatus, null, 2));

    // Try a direct check
    console.log('Performing direct health check...');
    const available = await checkServiceHealth('socialIntel');
    console.log('Direct health check result:', available);

    // Get final status
    const finalStatus = getServiceStatus('socialIntel');
    console.log('Final status:', JSON.stringify(finalStatus, null, 2));

    console.log('Debug health check completed.');
  } catch (error) {
    console.error('Error in health check debug:', error);
  }
}

// Run the debug function
run();
