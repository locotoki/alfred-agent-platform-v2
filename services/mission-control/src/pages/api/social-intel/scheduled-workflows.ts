import type { NextApiRequest, NextApiResponse } from 'next';
import { WorkflowSchedule } from '../../../types/youtube-workflows';

// Set the URL to the Social Intelligence Agent
const SOCIAL_INTEL_URL = process.env.SOCIAL_INTEL_URL || 'http://localhost:9000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // Only allow GET requests
  if (req.method !== 'GET') {
    return res.status(405).json({ detail: 'Method not allowed' });
  }

  try {
    // Call the Social Intelligence Agent API
    const response = await fetch(`${SOCIAL_INTEL_URL}/youtube/scheduled-workflows`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Check for errors
    if (!response.ok) {
      // If the service isn't available, return mock data for development
      if (response.status === 404 || response.status === 503) {
        console.warn('Social Intel API not available, returning mock data');
        return res.status(200).json(getMockScheduledWorkflows());
      }

      const errorData = await response.json();
      console.error('Social Intel API error:', errorData);
      return res.status(response.status).json({
        detail: errorData.detail || 'Failed to retrieve scheduled workflows',
      });
    }

    // Return the API response
    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    console.error('Error in scheduled workflows API handler:', error);

    // Return mock data if there's an error
    console.warn('Error connecting to Social Intel API, returning mock data');
    return res.status(200).json(getMockScheduledWorkflows());
  }
}

// Mock data for development and testing
function getMockScheduledWorkflows(): WorkflowSchedule[] {
  return [
    {
      id: 'sched-1234',
      workflow_type: 'niche-scout',
      parameters: { query: 'gaming' },
      frequency: 'daily',
      next_run: new Date(Date.now() + 86400000).toISOString(), // Tomorrow
      status: 'scheduled',
      created_at: new Date(Date.now() - 86400000).toISOString(), // Yesterday
      updated_at: new Date(Date.now() - 86400000).toISOString(), // Yesterday
      user_id: 'user-1'
    },
    {
      id: 'sched-2345',
      workflow_type: 'seed-to-blueprint',
      parameters: { niche: 'fitness' },
      frequency: 'weekly',
      next_run: new Date(Date.now() + 604800000).toISOString(), // Next week
      status: 'scheduled',
      created_at: new Date(Date.now() - 172800000).toISOString(), // 2 days ago
      updated_at: new Date(Date.now() - 172800000).toISOString(), // 2 days ago
      user_id: 'user-1'
    },
    {
      id: 'sched-3456',
      workflow_type: 'niche-scout',
      parameters: { query: 'cooking' },
      frequency: 'once',
      next_run: new Date(Date.now() + 259200000).toISOString(), // 3 days from now
      status: 'scheduled',
      created_at: new Date(Date.now() - 86400000).toISOString(), // Yesterday
      updated_at: new Date(Date.now() - 86400000).toISOString(), // Yesterday
      user_id: 'user-1'
    }
  ];
}
