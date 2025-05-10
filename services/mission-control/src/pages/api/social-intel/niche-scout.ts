import type { NextApiRequest, NextApiResponse } from 'next';

/**
 * Niche-Scout API Endpoint
 * 
 * This API proxy forwards requests to the Social Intelligence Agent's Niche-Scout workflow.
 * It handles the transformation of request parameters into the proper A2A envelope format
 * expected by the agent.
 * 
 * Query Parameters:
 * - query: Main search query (optional, defaults to general topics if not provided)
 * - category: Content category filter (optional, defaults to 'All')
 * - timeRange: Time range to analyze (optional, defaults to 'Last 30 days')
 * - demographics: Target demographic filter (optional, defaults to 'All')
 * 
 * Returns:
 * - 200: NicheScoutResult object with trending niches data
 * - 405: Method not allowed (only POST is supported)
 * - 500: Server error
 */

// Import our proxy helper
import { SOCIAL_INTEL_URL, getMockNicheScoutData, useMockData } from './proxy-helper';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ detail: 'Method not allowed' });
  }

  try {
    // Extract query parameter
    const { query } = req.query;

    // Prepare payload for the Social Intel Agent
    // The agent expects an A2A envelope with the intent YOUTUBE_NICHE_SCOUT
    const payload = {
      intent: 'YOUTUBE_NICHE_SCOUT',
      data: {
        queries: query ? [query as string] : ['mobile gaming tips', 'cooking recipes', 'fitness workouts'],
        category: req.query.category || 'All',
        timeRange: req.query.timeRange || 'Last 30 days',
        demographics: req.query.demographics || 'All'
      },
      task_id: `niche-scout-${Date.now()}`,
      trace_id: `trace-${Date.now()}`
    };

    console.log(`Running Niche-Scout with query: ${query || 'default queries'}`);

    // Call the Social Intelligence Agent API
    // Try multiple endpoint paths in sequence for better resilience
    const endpoints = [
      `${SOCIAL_INTEL_URL}/youtube/niche-scout`,
      `${SOCIAL_INTEL_URL}/api/youtube/niche-scout`,
      `${SOCIAL_INTEL_URL}/niche-scout`
    ];
    
    let response: Response | null = null;
    let lastError: any = null;
    
    // Try each endpoint until one works
    for (const endpoint of endpoints) {
      try {
        console.log(`Attempting to call endpoint: ${endpoint}`);
        response = await fetch(endpoint, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
          // Add timeout to prevent hanging requests
          signal: AbortSignal.timeout(60000) // 60 second timeout for better reliability with complex queries
        });
        
        if (response.ok) {
          console.log(`Successfully called endpoint: ${endpoint}`);
          break;
        } else {
          const errorText = await response.text();
          console.warn(`Endpoint ${endpoint} returned status ${response.status}: ${errorText}`);
          lastError = new Error(`API returned status ${response.status}: ${errorText}`);
        }
      } catch (error) {
        console.warn(`Failed to call endpoint ${endpoint}:`, error);
        lastError = error;
      }
    }

    // If all endpoints failed or returned errors
    if (!response || !response.ok) {
      console.error('All endpoints failed, returning mock data for development');
      
      // Use our helper to get mock data for development/testing
      const mockData = getMockNicheScoutData();
      
      console.log('SERVER: Returning mock data with ID:', mockData._id);\r\n      // Add mock data indicator flag\r\n      mockData._mock = true;\r\n      mockData._mockReason = 'API call failed';\r\n      mockData._mockTimestamp = new Date().toISOString();
      return res.status(200).json(mockData);
    }

    // Parse and return the successful API response
    const data = await response.json();
    
    // Add an _id field if not present (for result page retrieval)
    if (!data._id) {
      data._id = `niche-scout-${Date.now()}`;
    }
    
    console.log('Successfully ran Niche-Scout workflow, returning data with ID:', data._id);
    console.log('SERVER: Returning real API data with ID:', data._id);\r\nreturn res.status(200).json(data);
  } catch (error) {
    console.error('Error in Niche-Scout API handler:', error);
    
    // Check if we should use mock data
    if (useMockData(error)) {
      // Return mock data if there's an error connecting to the service
      console.warn('SERVER: API call failed, using mock data:', error);
      const mockData = getMockNicheScoutData();
      
      console.log('SERVER: Returning mock data with ID:', mockData._id);\r\n      // Add mock data indicator flag\r\n      mockData._mock = true;\r\n      mockData._mockReason = 'API call failed';\r\n      mockData._mockTimestamp = new Date().toISOString();
      return res.status(200).json(mockData);
    }
    
    // If not a network/connection error, return a proper error
    return res.status(500).json({ 
      error: 'Failed to run Niche-Scout workflow',
      message: error instanceof Error ? error.message : 'Unknown error',
      _id: `error-${Date.now()}`
    });
  }
}
