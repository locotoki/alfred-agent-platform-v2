// Check API configuration
async function checkApiConfig() {
  try {
    // Import the API config
    const apiConfig = await import('./lib/api-config.js');

    console.log('API Configuration:');
    console.log('SOCIAL_INTEL_URL:', apiConfig.SOCIAL_INTEL_URL);
    console.log('API_BASE_URL:', apiConfig.API_BASE_URL);
    console.log('FEATURES:', apiConfig.FEATURES);
    console.log('ENDPOINTS.HEALTH:', apiConfig.ENDPOINTS.HEALTH);
  } catch (error) {
    console.error('Error importing API config:', error.message);
  }
}

checkApiConfig();
