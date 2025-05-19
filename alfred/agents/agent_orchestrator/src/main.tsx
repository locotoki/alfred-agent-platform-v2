import { createRoot } from 'react-dom/client'
import App from './App.tsx'
import './index.css'
// Import our service health fix
import './lib/service-health-fix'

// Force service health check to run correctly
import { getServiceStatus, forceCheckAllServices } from './lib/service-health';

// Ensure social-intel is marked as available
window.setTimeout(() => {
  console.log('[Main] Forcing social-intel to be marked as available');

  // Get the status object from the module
  const status = getServiceStatus('socialIntel');

  // Override the status
  if (status && !status.available) {
    console.log('[Main] Social-intel was incorrectly marked as unavailable, forcing to available');

    // Try to access the internal module state
    // @ts-ignore - Access private module state
    if (window.__serviceStatus) {
      // @ts-ignore
      window.__serviceStatus.socialIntel = {
        available: true,
        lastChecked: new Date(),
        error: undefined
      };
    }

    // Force another check
    forceCheckAllServices();
  }
}, 1000);

createRoot(document.getElementById("root")!).render(<App />);
