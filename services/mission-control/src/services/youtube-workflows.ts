import { NicheScoutResult, BlueprintResult, WorkflowHistory, WorkflowSchedule } from '../types/youtube-workflows';

// Use local API proxy to avoid CORS issues
const SOCIAL_INTEL_URL = '/api/social-intel';

/**
 * Run the Niche-Scout workflow to find trending YouTube niches
 */
export async function runNicheScout(query?: string): Promise<NicheScoutResult> {
  const params = new URLSearchParams();
  if (query) {
    params.append('query', query);
  }

  try {
    const response = await fetch(`${SOCIAL_INTEL_URL}/niche-scout?${params.toString()}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      // Add timeout to prevent hanging requests
      signal: AbortSignal.timeout(30000) // 30 second timeout
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ detail: 'Failed to parse error response' }));
      throw new Error(error.detail || 'Failed to run Niche-Scout workflow');
    }

    return response.json();
  } catch (error) {
    console.error('Error running Niche-Scout workflow:', error);
    if (error instanceof TypeError && error.message.includes('fetch')) {
      throw new Error('Could not connect to Social Intelligence Agent. Please check if the service is running.');
    }
    throw error;
  }
}

/**
 * Run the Seed-to-Blueprint workflow to create a channel strategy
 */
export async function runSeedToBlueprint(params: { video_url?: string; niche?: string; analysisDepth?: string }): Promise<BlueprintResult> {
  const urlParams = new URLSearchParams();
  if (params.video_url) {
    urlParams.append('video_url', params.video_url);
  }
  if (params.niche) {
    urlParams.append('niche', params.niche);
  }
  if (params.analysisDepth) {
    urlParams.append('analysisDepth', params.analysisDepth);
  }

  try {
    const response = await fetch(`${SOCIAL_INTEL_URL}/seed-to-blueprint?${urlParams.toString()}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      // Add timeout to prevent hanging requests
      signal: AbortSignal.timeout(60000) // 60 second timeout for this more complex workflow
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ detail: 'Failed to parse error response' }));
      throw new Error(error.detail || 'Failed to run Seed-to-Blueprint workflow');
    }

    return response.json();
  } catch (error) {
    console.error('Error running Seed-to-Blueprint workflow:', error);
    if (error instanceof TypeError && error.message.includes('fetch')) {
      throw new Error('Could not connect to Social Intelligence Agent. Please check if the service is running.');
    }
    throw error;
  }
}

/**
 * Get workflow history
 */
export async function getWorkflowHistory(): Promise<WorkflowHistory[]> {
  const response = await fetch(`${SOCIAL_INTEL_URL}/workflow-history`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail || 'Failed to get workflow history');
  }

  return response.json();
}

/**
 * Get scheduled workflows
 */
export async function getScheduledWorkflows(): Promise<WorkflowSchedule[]> {
  const response = await fetch(`${SOCIAL_INTEL_URL}/scheduled-workflows`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail || 'Failed to get scheduled workflows');
  }

  return response.json();
}

/**
 * Schedule a workflow
 */
export async function scheduleWorkflow(data: {
  workflow_type: 'niche-scout' | 'seed-to-blueprint';
  parameters: Record<string, any>;
  frequency: 'daily' | 'weekly' | 'monthly' | 'once';
  next_run: string;
}): Promise<WorkflowSchedule> {
  const response = await fetch(`${SOCIAL_INTEL_URL}/schedule-workflow`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail || 'Failed to schedule workflow');
  }

  return response.json();
}

/**
 * Get workflow result by ID
 */
export async function getWorkflowResult(id: string, type: 'niche-scout' | 'seed-to-blueprint'): Promise<NicheScoutResult | BlueprintResult> {
  const response = await fetch(`${SOCIAL_INTEL_URL}/workflow-result/${id}?type=${type}`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail || 'Failed to get workflow result');
  }

  return response.json();
}