import type { NextApiRequest, NextApiResponse } from 'next';
import { mockNicheScoutResult, mockBlueprintResult } from '../mock-data';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { id, type } = req.query;

    if (!id || !type) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }

    // Return appropriate mock data based on workflow type
    if (type === 'niche-scout') {
      return res.status(200).json(mockNicheScoutResult);
    } else if (type === 'seed-to-blueprint') {
      return res.status(200).json(mockBlueprintResult);
    } else {
      return res.status(400).json({ error: 'Invalid workflow type' });
    }
  } catch (error) {
    console.error('Error in workflow-result API:', error);
    return res.status(500).json({
      error: 'Failed to retrieve workflow result',
      detail: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
