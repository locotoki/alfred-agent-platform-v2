import type { NextApiRequest, NextApiResponse } from 'next';
import { WorkflowHistory } from '../../../types/youtube-workflows';

// Set the URL to the Social Intelligence Agent
const SOCIAL_INTEL_URL = process.env.SOCIAL_INTEL_URL || 'http://localhost:9000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // Only allow GET requests
  if (req.method !== 'GET') {
    return res.status(405).json({ detail: 'Method not allowed' });
  }

  try {
    // Call the Social Intelligence Agent API
    const response = await fetch(`${SOCIAL_INTEL_URL}/youtube/workflow-history`, {
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
        return res.status(200).json(getMockWorkflowHistory());
      }
      
      const errorData = await response.json();
      console.error('Social Intel API error:', errorData);
      return res.status(response.status).json({
        detail: errorData.detail || 'Failed to retrieve workflow history',
      });
    }

    // Return the API response
    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    console.error('Error in workflow history API handler:', error);
    
    // Return mock data if there's an error
    console.warn('Error connecting to Social Intel API, returning mock data');
    return res.status(200).json(getMockWorkflowHistory());
  }
}

// Mock data for development and testing
function getMockWorkflowHistory(): WorkflowHistory[] {
  return [
    {
      id: 'wf-1234',
      workflow_type: 'niche-scout',
      parameters: { query: 'mobile gaming' },
      status: 'completed',
      started_at: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
      completed_at: new Date(Date.now() - 3540000).toISOString(), // 59 minutes ago
      result_url: '/api/social-intel/workflow-result/wf-1234',
      user_id: 'user-1'
    },
    {
      id: 'wf-2345',
      workflow_type: 'seed-to-blueprint',
      parameters: { video_url: 'https://youtube.com/watch?v=example123' },
      status: 'completed',
      started_at: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
      completed_at: new Date(Date.now() - 7080000).toISOString(), // 1 hour 58 minutes ago
      result_url: '/api/social-intel/workflow-result/wf-2345',
      user_id: 'user-1'
    },
    {
      id: 'wf-3456',
      workflow_type: 'niche-scout',
      parameters: { query: 'cooking recipes' },
      status: 'completed',
      started_at: new Date(Date.now() - 86400000).toISOString(), // 1 day ago
      completed_at: new Date(Date.now() - 86340000).toISOString(), // 23 hours 59 minutes ago
      result_url: '/api/social-intel/workflow-result/wf-3456',
      user_id: 'user-1'
    },
    {
      id: 'wf-4567',
      workflow_type: 'seed-to-blueprint',
      parameters: { niche: 'fitness' },
      status: 'completed',
      started_at: new Date(Date.now() - 172800000).toISOString(), // 2 days ago
      completed_at: new Date(Date.now() - 172740000).toISOString(), // 1 day 23 hours 59 minutes ago
      result_url: '/api/social-intel/workflow-result/wf-4567',
      user_id: 'user-1'
    }
  ];
}