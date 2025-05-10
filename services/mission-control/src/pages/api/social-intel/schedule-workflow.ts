import type { NextApiRequest, NextApiResponse } from 'next';
import { WorkflowSchedule } from '../../../types/youtube-workflows';

// Set the URL to the Social Intelligence Agent
const SOCIAL_INTEL_URL = process.env.SOCIAL_INTEL_URL || 'http://localhost:9000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ detail: 'Method not allowed' });
  }

  try {
    // Extract the request body
    const { workflow_type, parameters, frequency, next_run } = req.body;

    // Validate required fields
    if (!workflow_type || !['niche-scout', 'seed-to-blueprint'].includes(workflow_type)) {
      return res.status(400).json({ detail: 'Valid workflow_type is required' });
    }

    if (!parameters) {
      return res.status(400).json({ detail: 'Parameters are required' });
    }

    if (!frequency || !['daily', 'weekly', 'monthly', 'once'].includes(frequency)) {
      return res.status(400).json({ detail: 'Valid frequency is required' });
    }

    if (!next_run) {
      return res.status(400).json({ detail: 'Next run date is required' });
    }

    // Prepare the payload
    const payload = {
      workflow_type,
      parameters,
      frequency,
      next_run
    };

    // Call the Social Intelligence Agent API
    const response = await fetch(`${SOCIAL_INTEL_URL}/youtube/schedule-workflow`, {
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
        return res.status(200).json(getMockScheduledWorkflow(workflow_type, parameters, frequency, next_run));
      }
      
      const errorData = await response.json();
      console.error('Social Intel API error:', errorData);
      return res.status(response.status).json({
        detail: errorData.detail || 'Failed to schedule workflow',
      });
    }

    // Return the API response
    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    console.error('Error in schedule workflow API handler:', error);
    return res.status(500).json({
      detail: error instanceof Error ? error.message : 'Internal server error',
    });
  }
}

// Mock data for development and testing
function getMockScheduledWorkflow(
  workflow_type: string, 
  parameters: Record<string, any>, 
  frequency: string, 
  next_run: string
): WorkflowSchedule {
  return {
    id: `sched-${Date.now()}`,
    workflow_type: workflow_type as 'niche-scout' | 'seed-to-blueprint',
    parameters,
    frequency: frequency as 'daily' | 'weekly' | 'monthly' | 'once',
    next_run,
    status: 'scheduled',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    user_id: 'user-1'
  };
}