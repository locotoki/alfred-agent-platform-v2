import type { NextApiRequest, NextApiResponse } from 'next';
import { mockScheduledWorkflows } from './mock-data';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Return mock data for scheduled workflows
    return res.status(200).json(mockScheduledWorkflows);
  } catch (error) {
    console.error('Error in scheduled-workflows API:', error);
    return res.status(500).json({ 
      error: 'Failed to retrieve scheduled workflows',
      detail: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}