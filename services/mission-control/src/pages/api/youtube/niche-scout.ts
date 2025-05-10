import type { NextApiRequest, NextApiResponse } from 'next';
import { mockNicheScoutResult } from './mock-data';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // In a real implementation, we would pass the query parameter to the social-intel agent
    // const { query } = req.query;
    
    // Return mock data for now
    return res.status(200).json(mockNicheScoutResult);
  } catch (error) {
    console.error('Error in niche-scout API:', error);
    return res.status(500).json({ 
      error: 'Failed to process niche-scout workflow',
      detail: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}