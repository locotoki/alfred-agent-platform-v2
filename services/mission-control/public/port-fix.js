/**
 * Port Fix Script
 * 
 * This script ensures that any hardcoded port references in API calls are 
 * properly redirected to the current window's origin. Handles port variations.
 * This fixes any issues with API requests when the server is running on a different port.
 */
(function() {
  // Original fetch function
  const originalFetch = window.fetch;

  // Override fetch to normalize URLs with wrong ports
  window.fetch = function(url, options) {
    if (typeof url === 'string') {
      const currentOrigin = window.location.origin;
      
      // Replace hardcoded ports with current window origin
      if (url.includes('localhost:3000') || url.includes('localhost:3003') || url.includes('localhost:3005') || url.includes('localhost:3007')) {
        url = url.replace(/http:\/\/localhost:(3000|3003|3005|3007)/g, currentOrigin);
        console.log('Port fix: Redirecting API call to', url);
      }
      
      // Special handling for Supabase REST API calls (keep those at 3000)
      if (url.includes('/rest/v1/') && !currentOrigin.includes('3000')) {
        url = url.replace(currentOrigin, 'http://localhost:3000');
        console.log('Port fix: Redirecting Supabase API call to port 3000:', url);
      }
    }
    return originalFetch.call(this, url, options);
  };

  console.log('Port fix script loaded. API calls will use correct port.', window.location.origin);
  
  // Add this info to the console to help with debugging
  console.info('Mission Control UI is running on port 3007. Supabase REST API is on port 3000.');
})();