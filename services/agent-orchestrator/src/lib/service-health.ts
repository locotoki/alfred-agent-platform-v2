import { SOCIAL_INTEL_URL, API_BASE_URL } from './api-config';

/**
 * Interface for service health status
 */
export interface ServiceStatus {
  available: boolean;
  lastChecked: Date;
  error?: string;
}

/**
 * Service health status tracker
 */
const serviceStatus: Record<string, ServiceStatus> = {
  socialIntel: {
    available: false, // Start pessimistic
    lastChecked: new Date(0) // Force a recheck immediately
  }
};

/**
 * Check if a service is available
 */
export async function checkServiceHealth(service: 'socialIntel'): Promise<boolean> {
  console.log(`[Health] checkServiceHealth called for ${service}`);
  console.log(`[Health] Current time: ${new Date().toISOString()}`);

  // If we checked recently (last 30 seconds), return cached status
  const lastCheck = serviceStatus[service]?.lastChecked;
  if (lastCheck && new Date().getTime() - lastCheck.getTime() < 30000) {
    console.log(`[Health] Using cached health status for ${service}: ${serviceStatus[service]?.available}`);
    console.log(`[Health] Last checked: ${lastCheck.toISOString()}`);
    return serviceStatus[service]?.available || false;
  }

  console.log(`[Health] Cache expired or not available, performing fresh check`);

  // Try multiple endpoint variations, prioritizing direct container access
  const endpoints = [
    // Container DNS name (works in Docker network)
    `http://social-intel:9000/health/`,
    `http://social-intel:9000/health`,

    // Direct IP address (works in Docker network)
    `http://172.18.0.2:9000/health/`,
    `http://172.18.0.2:9000/health`,

    // From API config (might be localhost which works outside container)
    `${API_BASE_URL}/health/`,
    `${API_BASE_URL}/health`,

    // Localhost (works outside container)
    `http://localhost:9000/health/`,
    `http://localhost:9000/health`
  ];

  for (const endpoint of endpoints) {
    try {
      console.log(`[Health] Checking ${service} health at ${endpoint}`);

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

      // If we got a redirect, follow it
      if (response.status >= 300 && response.status < 400 && response.headers.has('location')) {
        const redirectUrl = response.headers.get('location') || '';
        console.log(`[Health] Following redirect to: ${redirectUrl}`);

        const redirectResponse = await fetch(redirectUrl, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          signal: AbortSignal.timeout(5000)
        });

        console.log(`[Health] Redirect response status: ${redirectResponse.status}`);

        if (redirectResponse.ok) {
          let responseData;
          try {
            responseData = await redirectResponse.json();
            console.log(`[Health] Redirect response data:`, responseData);
          } catch (e) {
            console.log(`[Health] Failed to parse redirect response: ${e.message}`);
          }

          const now = new Date();
          serviceStatus[service] = {
            available: true,
            lastChecked: now,
            error: undefined
          };

          console.log(`[Health] Service ${service} available via redirect: true, lastChecked=${now.toISOString()}`);
          console.log(`[Health] Current serviceStatus object:`, JSON.stringify(serviceStatus, null, 2));
          return true;
        }
      }

      // Check if original response was successful
      if (response.ok) {
        let responseData;
        try {
          responseData = await response.json();
          console.log(`[Health] Response data:`, responseData);
        } catch (e) {
          console.log(`[Health] Failed to parse response: ${e.message}`);
        }

        const now = new Date();
        serviceStatus[service] = {
          available: true,
          lastChecked: now,
          error: undefined
        };

        console.log(`[Health] Service ${service} available: true, lastChecked=${now.toISOString()}`);
        console.log(`[Health] Current serviceStatus object:`, JSON.stringify(serviceStatus, null, 2));
        return true;
      }
    } catch (error) {
      console.error(`[Health] Error checking ${service} health at ${endpoint}:`, error);
      // Continue to the next endpoint
    }
  }

  // If we reach here, all endpoints failed
  console.error(`[Health] All health check endpoints failed for ${service}`);

  const now = new Date();
  serviceStatus[service] = {
    available: false,
    lastChecked: now,
    error: 'All health check endpoints failed'
  };

  console.log(`[Health] Setting service ${service} status: available=${false}, lastChecked=${now.toISOString()}`);
  console.log(`[Health] Current serviceStatus object:`, JSON.stringify(serviceStatus, null, 2));

  return false;
}

/**
 * Get the current health status of services
 */
export function getServiceStatus(service: 'socialIntel'): ServiceStatus {
  console.log(`[Health] getServiceStatus called for ${service} at ${new Date().toISOString()}`);

  // If we've never checked or it's been more than 2 minutes, trigger a check
  const lastCheck = serviceStatus[service]?.lastChecked;
  if (!lastCheck || new Date().getTime() - lastCheck.getTime() > 120000) {
    console.log(`[Health] Status stale or missing for ${service}, triggering check`);
    // Don't await this, just trigger the check
    checkServiceHealth(service)
      .then(result => {
        console.log(`[Health] Background check result for ${service}: ${result}`);
      })
      .catch(error => {
        console.error(`[Health] Background check error for ${service}:`, error);
      });
  } else {
    console.log(`[Health] Using cached status for ${service}: ${serviceStatus[service]?.available}`);
  }

  const result = serviceStatus[service] || { available: false, lastChecked: new Date() };
  console.log(`[Health] Returning status for ${service}:`, JSON.stringify(result, null, 2));
  return result;
}

/**
 * Force check of all services
 */
export function forceCheckAllServices(): void {
  console.log('[Health] Forcing check of all services at', new Date().toISOString());
  console.log('[Health] Current status before check:', JSON.stringify(serviceStatus, null, 2));
  // Don't await, just trigger checks
  checkServiceHealth('socialIntel')
    .then(result => {
      console.log(`[Health] Force check result for socialIntel: ${result}`);
    })
    .catch(error => {
      console.error(`[Health] Force check error for socialIntel:`, error);
    });
}

// Check health on module load
forceCheckAllServices();
