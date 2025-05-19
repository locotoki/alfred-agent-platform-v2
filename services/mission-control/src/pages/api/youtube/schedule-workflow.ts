import type { NextApiRequest, NextApiResponse } from 'next';
import { mockScheduledWorkflows } from './mock-data';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // In production, we would create a new scheduled workflow here
    // For now, return the first mock scheduled workflow
    return res.status(200).json(mockScheduledWorkflows[0]);
  } catch (error) {
    console.error('Error in schedule-workflow API:', error);
    return res.status(500).json({
      error: 'Failed to schedule workflow',
      detail: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
