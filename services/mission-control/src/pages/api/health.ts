import type { NextApiRequest, NextApiResponse } from 'next';

/**
 * API Health Check Endpoint
 * 
 * This endpoint returns information about the running services and their connectivity status.
 * It's useful for diagnosing API connection issues with the Social Intelligence Agent.
 */

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const SOCIAL_INTEL_URL = process.env.SOCIAL_INTEL_URL || 'http://localhost:9000';
  
  // Check connections and build status information
  const status = {
    mission_control: {
      status: 'online',
      version: '1.0.0',
      time: new Date().toISOString(),
    },
    social_intel: await checkServiceStatus(SOCIAL_INTEL_URL),
    api: {
      social_intel_url: SOCIAL_INTEL_URL,
      server_url: process.env.NEXT_PUBLIC_SERVER_URL || 'http://localhost:3000',
      current_host: req.headers.host || 'unknown',
    },
    env: {
      NODE_ENV: process.env.NODE_ENV || 'development',
      // Only include non-sensitive environment variables
      NEXT_PUBLIC_SERVER_URL: process.env.NEXT_PUBLIC_SERVER_URL,
      NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL,
    }
  };

  // Return the health check response
  return res.status(200).json(status);
}

/**
 * Check if a service is available
 */
async function checkServiceStatus(url: string): Promise<{status: string, message: string}> {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);
    
    const response = await fetch(`${url}/health`, {
      method: 'GET',
      signal: controller.signal,
    }).catch(() => null);
    
    clearTimeout(timeoutId);
    
    if (response && response.ok) {
      return { status: 'online', message: 'Service is responding correctly' };
    } else {
      return { status: 'offline', message: 'Service is not responding or returned an error' };
    }
  } catch (error) {
    return { status: 'error', message: error instanceof Error ? error.message : 'Unknown error' };
  }
}