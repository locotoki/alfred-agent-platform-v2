import type { NextApiRequest, NextApiResponse } from 'next';
import { mockBlueprintResult } from './mock-data';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // In a real implementation, we would pass the video_url or niche parameter to the social-intel agent
    // const { video_url, niche } = req.query;

    // Return mock data for now
    return res.status(200).json(mockBlueprintResult);
  } catch (error) {
    console.error('Error in seed-to-blueprint API:', error);
    return res.status(500).json({
      error: 'Failed to process seed-to-blueprint workflow',
      detail: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
