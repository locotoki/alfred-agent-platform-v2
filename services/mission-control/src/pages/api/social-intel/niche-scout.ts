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

// Set the URL to the Social Intelligence Agent
const SOCIAL_INTEL_URL = process.env.SOCIAL_INTEL_URL || 'http://localhost:9000';

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

    // Call the Social Intelligence Agent API
    const response = await fetch(`${SOCIAL_INTEL_URL}/youtube/niche-scout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    // Check for errors
    if (!response.ok) {
      // If the service isn't available, return mock data for development
      if (response.status === 404 || response.status === 503) {
        console.warn('Social Intel API not available, returning mock data');
        const mockData = {
          run_date: new Date().toISOString(),
          trending_niches: Array.from({ length: 20 }, (_, i) => ({
            query: ['mobile gaming tips', 'coding tutorials', 'fitness workouts', 'cooking recipes', 'travel vlogs'][i % 5],
            view_sum: Math.floor(Math.random() * 5000000) + 1000000,
            rsv: Math.random() * 100,
            view_rank: i + 1,
            rsv_rank: i + 1,
            score: Math.random() * 0.5 + 0.5,
            x: Math.random() * 100,
            y: Math.random() * 100,
            niche: i % 5
          })),
          top_niches: Array.from({ length: 10 }, (_, i) => ({
            query: ['mobile gaming tips', 'coding tutorials', 'fitness workouts', 'cooking recipes', 'travel vlogs'][i % 5],
            view_sum: Math.floor(Math.random() * 5000000) + 1000000,
            rsv: Math.random() * 100,
            view_rank: i + 1,
            rsv_rank: i + 1,
            score: Math.random() * 0.5 + 0.5,
            x: Math.random() * 100,
            y: Math.random() * 100,
            niche: i % 5
          }))
        };
        return res.status(200).json(mockData);
      }
      
      const errorData = await response.json();
      console.error('Social Intel API error:', errorData);
      return res.status(response.status).json({
        detail: errorData.detail || 'Failed to process Niche-Scout workflow',
      });
    }

    // Return the API response
    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    console.error('Error in Niche-Scout API handler:', error);
    return res.status(500).json({
      detail: error instanceof Error ? error.message : 'Internal server error',
    });
  }
}