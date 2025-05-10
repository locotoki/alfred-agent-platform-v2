import type { NextApiRequest, NextApiResponse } from 'next';
import { mockWorkflowHistory } from './mock-data';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Return mock data for workflow history
    return res.status(200).json(mockWorkflowHistory);
  } catch (error) {
    console.error('Error in workflow-history API:', error);
    return res.status(500).json({ 
      error: 'Failed to retrieve workflow history',
      detail: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}