
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
  // If we checked recently (last 30 seconds), return cached status
  const lastCheck = serviceStatus[service]?.lastChecked;
  if (lastCheck && new Date().getTime() - lastCheck.getTime() < 30000) {
    console.log(`[Health] Using cached health status for ${service}: ${serviceStatus[service]?.available}`);
    return serviceStatus[service]?.available || false;
  }
  
  // Try multiple endpoint variations
  const endpoints = [
    `${API_BASE_URL}/health/`,
    `${API_BASE_URL}/health`,
    `http://social-intel:9000/health/`,
    `http://social-intel:9000/health`
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
          
          serviceStatus[service] = {
            available: true,
            lastChecked: new Date(),
            error: undefined
          };
          
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
        
        serviceStatus[service] = {
          available: true,
          lastChecked: new Date(),
          error: undefined
        };
        
        console.log(`[Health] Service ${service} available: true`);
        return true;
      }
    } catch (error) {
      console.error(`[Health] Error checking ${service} health at ${endpoint}:`, error);
      // Continue to the next endpoint
    }
  }
  
  // If we reach here, all endpoints failed
  console.error(`[Health] All health check endpoints failed for ${service}`);
  
  serviceStatus[service] = {
    available: false,
    lastChecked: new Date(),
    error: 'All health check endpoints failed'
  };
  
  return false;
}

/**
 * Get the current health status of services
 */
export function getServiceStatus(service: 'socialIntel'): ServiceStatus {
  // If we've never checked or it's been more than 2 minutes, trigger a check
  const lastCheck = serviceStatus[service]?.lastChecked;
  if (!lastCheck || new Date().getTime() - lastCheck.getTime() > 120000) {
    // Don't await this, just trigger the check
    checkServiceHealth(service);
  }
  
  return serviceStatus[service] || { available: false, lastChecked: new Date() };
}

/**
 * Force check of all services
 */
export function forceCheckAllServices(): void {
  console.log('[Health] Forcing check of all services');
  checkServiceHealth('socialIntel');
}

// Check health on module load
forceCheckAllServices();
