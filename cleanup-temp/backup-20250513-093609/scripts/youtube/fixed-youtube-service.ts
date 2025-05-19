import { createApiUrl, ENDPOINTS, FEATURES, API_BASE_URL } from './api-config';
import { mockNicheScoutResult, mockBlueprintResult, mockWorkflowHistory } from './mock-data';
import { ServiceStatus, checkServiceHealth, getServiceStatus, forceCheckAllServices } from './service-health';

// Re-export service health functions
export { checkServiceHealth, getServiceStatus, forceCheckAllServices };
export type { ServiceStatus };

// Call health check on module load to verify connectivity
forceCheckAllServices();

// Types for YouTube workflow responses
export interface NicheScoutResult {
  run_date: string;
  trending_niches: YouTubeNiche[];
  top_niches: YouTubeNiche[];
  visualization_url?: string;
  actual_cost?: number;
  actual_processing_time?: number;
  status?: string;
}

export interface BlueprintResult {
  run_date: string;
  seed_url: string;
  seed_data: YouTubeVideo;
  top_channels: YouTubeChannel[];
  gap_analysis: YouTubeGap[];
  blueprint: YouTubeBlueprint;
  blueprint_url: string;
}

export interface WorkflowHistory {
  id: string;
  workflow_type: 'niche-scout' | 'seed-to-blueprint';
  parameters: Record<string, any>;
  status: 'running' | 'completed' | 'error';
  started_at: string;
  completed_at?: string;
  result_url?: string;
  user_id: string;
}

export interface WorkflowSchedule {
  id: string;
  workflow_type: 'niche-scout' | 'seed-to-blueprint';
  parameters: Record<string, any>;
  frequency: 'daily' | 'weekly' | 'monthly' | 'once';
  next_run: string;
  status: 'scheduled' | 'running' | 'completed' | 'error';
  created_at: string;
  updated_at: string;
  user_id: string;
}

export interface YouTubeNiche {
  query: string;
  view_sum: number;
  rsv: number;
  view_rank: number;
  rsv_rank: number;
  score: number;
  x: number;
  y: number;
  niche: number;
}

export interface YouTubeVideo {
  video_id: string;
  title: string;
  channel_id: string;
  channel_name: string;
  view_count: number;
  like_count?: number;
  comment_count?: number;
  published_at: string;
  duration: string;
  tags: string[];
  description: string;
}

export interface YouTubeChannel {
  channel_id: string;
  channel_name: string;
  subscribers: number;
  total_views: number;
  video_count: number;
  recent_upload_count: number;
  thirty_day_delta: number;
  primary_topics: string[];
  format_distribution?: Record<string, number>;
}

export interface YouTubeGap {
  keyword: string;
  seed_coverage: number;
  competitor_coverage: Record<string, number>;
  opportunity_score: number;
}

export interface YouTubeBlueprint {
  positioning: string;
  content_pillars: string[];
  format_mix: Record<string, number>;
  roadmap: Record<string, string[]>;
  ai_production_tips: string[];
  coppa_checklist: Array<{
    item: string;
    status: string;
  }>;
}

/**
 * Run the Niche-Scout workflow to find trending niches
 */
export async function runNicheScout(config: {
  category: string;
  subcategory: string;
  budget?: number;
  dataSources?: Record<string, any>;
  forceOfflineMode?: boolean;
}): Promise<NicheScoutResult> {
  // Return mock data if feature flag is enabled or in offline mode
  const useOfflineMode = FEATURES.USE_MOCK_DATA || config.forceOfflineMode;

  if (useOfflineMode) {
    console.log('Using mock data for Niche-Scout workflow');
    await new Promise(resolve => setTimeout(resolve, 1500));
    return {
      ...mockNicheScoutResult,
      actual_cost: config.budget ? config.budget * 0.95 : 100,
      actual_processing_time: 120 + Math.floor(Math.random() * 30),
      status: 'completed'
    };
  }

  // Check if service is available
  const isServiceAvailable = await checkServiceHealth('socialIntel');
  if (!isServiceAvailable) {
    console.warn('Social Intelligence service is unavailable, falling back to mock data');
    return {
      ...mockNicheScoutResult,
      actual_cost: config.budget ? config.budget * 0.95 : 100,
      actual_processing_time: 120 + Math.floor(Math.random() * 30),
      status: 'completed (offline mode)'
    };
  }

  try {
    console.log('Running Niche-Scout workflow with config:', config);
    const response = await fetch(createApiUrl(ENDPOINTS.NICHE_SCOUT), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        category: config.category,
        subcategory: config.subcategory,
        budget: config.budget || 100,
        data_sources: config.dataSources
      }),
      signal: AbortSignal.timeout(30000) // 30 second timeout
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ detail: 'Unknown error' }));
      console.error('Niche-Scout API error response:', errorData);
      throw new Error(errorData.detail || errorData.error || `Failed to run Niche-Scout workflow: ${response.status} ${response.statusText}`);
    }

    try {
      const data = await response.json();
      console.log('Niche-Scout API success response:', data);
      return data;
    } catch (parseError) {
      console.error('Error parsing Niche-Scout API response:', parseError);
      throw new Error('Failed to parse Niche-Scout workflow response');
    }
  } catch (error) {
    console.error('Error running Niche-Scout workflow:', error);

    // Return mock data for graceful degradation
    console.warn('Falling back to mock data due to network error');
    forceCheckAllServices(); // Re-check service health

    return {
      ...mockNicheScoutResult,
      actual_cost: config.budget ? config.budget * 0.95 : 100,
      actual_processing_time: 120 + Math.floor(Math.random() * 30),
      status: 'completed (offline mode)'
    };
  }
}

/**
 * Run the Seed-to-Blueprint workflow to create a channel strategy
 */
export async function runSeedToBlueprint(params: {
  video_url?: string;
  niche?: string;
  analysisDepth?: string;
  forceOfflineMode?: boolean;
}): Promise<BlueprintResult> {
  // Return mock data if feature flag is enabled or in offline mode
  const useOfflineMode = FEATURES.USE_MOCK_DATA || params.forceOfflineMode;

  if (useOfflineMode) {
    console.log('Using mock data for Seed-to-Blueprint workflow');
    await new Promise(resolve => setTimeout(resolve, 2500));
    return {
      ...mockBlueprintResult,
      status: 'completed'
    };
  }

  // Check if service is available
  const isServiceAvailable = await checkServiceHealth('socialIntel');
  if (!isServiceAvailable) {
    console.warn('Social Intelligence service is unavailable, falling back to mock data');
    return {
      ...mockBlueprintResult,
      status: 'completed (offline mode)'
    };
  }

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
    console.log('Running Seed-to-Blueprint workflow with params:', params);
    const response = await fetch(createApiUrl(ENDPOINTS.SEED_TO_BLUEPRINT, urlParams.toString()), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      signal: AbortSignal.timeout(40000) // 40 second timeout (longer than niche scout)
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ detail: 'Unknown error' }));
      console.error('Seed-to-Blueprint API error response:', errorData);
      throw new Error(errorData.detail || errorData.error || `Failed to run Seed-to-Blueprint workflow: ${response.status} ${response.statusText}`);
    }

    try {
      const data = await response.json();
      console.log('Seed-to-Blueprint API success response:', data);
      return data;
    } catch (parseError) {
      console.error('Error parsing Seed-to-Blueprint API response:', parseError);
      throw new Error('Failed to parse Seed-to-Blueprint workflow response');
    }
  } catch (error) {
    console.error('Error running Seed-to-Blueprint workflow:', error);

    // Update service status if there's a network issue
    if (error instanceof TypeError || (error instanceof Error && error.name === 'AbortError')) {
      forceCheckAllServices(); // Re-check service health
    }

    // Fall back to mock data for graceful degradation
    console.warn('Falling back to mock data due to network error');
    return {
      ...mockBlueprintResult,
      status: 'completed (offline mode)'
    };
  }
}

/**
 * Get workflow history
 */
export async function getWorkflowHistory(options?: { forceOfflineMode?: boolean }): Promise<WorkflowHistory[]> {
  // Return mock data if feature flag is enabled or in offline mode
  const useOfflineMode = FEATURES.USE_MOCK_DATA || options?.forceOfflineMode;

  if (useOfflineMode) {
    console.log('Using mock data for workflow history');
    await new Promise(resolve => setTimeout(resolve, 800));
    return mockWorkflowHistory;
  }

  // Check if service is available
  const isServiceAvailable = await checkServiceHealth('socialIntel');
  if (!isServiceAvailable) {
    console.warn('Social Intelligence service is unavailable, falling back to mock data');
    return mockWorkflowHistory;
  }

  try {
    console.log('Fetching workflow history');
    const response = await fetch(createApiUrl(ENDPOINTS.WORKFLOW_HISTORY), {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      signal: AbortSignal.timeout(10000) // 10 second timeout
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ detail: 'Unknown error' }));
      console.error('Workflow history API error response:', errorData);
      throw new Error(errorData.detail || errorData.error || `Failed to get workflow history: ${response.status} ${response.statusText}`);
    }

    try {
      const data = await response.json();
      console.log('Workflow history API success response');
      return data;
    } catch (parseError) {
      console.error('Error parsing workflow history API response:', parseError);
      throw new Error('Failed to parse workflow history response');
    }
  } catch (error) {
    console.error('Error getting workflow history:', error);

    // Check service health
    forceCheckAllServices(); // Re-check service health

    // Fall back to mock data for graceful degradation
    console.warn('Falling back to mock workflow history due to error');
    return mockWorkflowHistory;
  }
}

/**
 * Get workflow result by ID
 */
export async function getWorkflowResult(
  id: string,
  type: 'niche-scout' | 'seed-to-blueprint',
  options?: { forceOfflineMode?: boolean }
): Promise<NicheScoutResult | BlueprintResult> {
  // Return mock data if feature flag is enabled or in offline mode
  const useOfflineMode = FEATURES.USE_MOCK_DATA || options?.forceOfflineMode;

  if (useOfflineMode) {
    console.log(`Using mock data for ${type} result`);
    await new Promise(resolve => setTimeout(resolve, 1000));
    return type === 'niche-scout' ? mockNicheScoutResult : mockBlueprintResult;
  }

  // Check if service is available
  const isServiceAvailable = await checkServiceHealth('socialIntel');
  if (!isServiceAvailable) {
    console.warn('Social Intelligence service is unavailable, falling back to mock data');
    return type === 'niche-scout' ? mockNicheScoutResult : mockBlueprintResult;
  }

  const params = new URLSearchParams();
  params.append('type', type);

  try {
    console.log(`Fetching workflow result for ${type} with ID ${id}`);
    const response = await fetch(createApiUrl(`${ENDPOINTS.WORKFLOW_RESULT}/${id}`, params.toString()), {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      signal: AbortSignal.timeout(15000) // 15 second timeout
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ detail: 'Unknown error' }));
      console.error('Workflow result API error response:', errorData);
      throw new Error(errorData.detail || errorData.error || `Failed to get workflow result: ${response.status} ${response.statusText}`);
    }

    try {
      const data = await response.json();
      console.log(`Workflow result API success response for ${type}`);
      return data;
    } catch (parseError) {
      console.error('Error parsing workflow result API response:', parseError);
      throw new Error('Failed to parse workflow result response');
    }
  } catch (error) {
    console.error(`Error getting ${type} workflow result:`, error);

    // Check service health
    forceCheckAllServices(); // Re-check service health

    // Fall back to mock data if API fails
    console.warn(`Falling back to mock ${type} result data due to error`);
    return type === 'niche-scout' ? mockNicheScoutResult : mockBlueprintResult;
  }
}

/**
 * Schedule a workflow
 */
export async function scheduleWorkflow(config: {
  workflow_type: 'niche-scout' | 'seed-to-blueprint';
  parameters: Record<string, any>;
  frequency: 'daily' | 'weekly' | 'monthly' | 'once';
  next_run?: string;
  forceOfflineMode?: boolean;
}): Promise<WorkflowSchedule> {
  // Return mock data if feature flag is enabled or in offline mode
  const useOfflineMode = FEATURES.USE_MOCK_DATA || config.forceOfflineMode;

  if (useOfflineMode) {
    console.log('Using mock data for scheduling workflow');
    await new Promise(resolve => setTimeout(resolve, 800));
    return {
      id: `mock-schedule-${Date.now()}`,
      workflow_type: config.workflow_type,
      parameters: config.parameters,
      frequency: config.frequency,
      next_run: config.next_run || new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      status: 'scheduled',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      user_id: "user-1"
    };
  }

  // Check if service is available
  const isServiceAvailable = await checkServiceHealth('socialIntel');
  if (!isServiceAvailable) {
    console.warn('Social Intelligence service is unavailable, falling back to mock data');
    return {
      id: `mock-schedule-${Date.now()}`,
      workflow_type: config.workflow_type,
      parameters: config.parameters,
      frequency: config.frequency,
      next_run: config.next_run || new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      status: 'scheduled',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      user_id: "user-1"
    };
  }

  try {
    console.log('Scheduling workflow with config:', config);
    const response = await fetch(createApiUrl(ENDPOINTS.SCHEDULE_WORKFLOW), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        workflow_type: config.workflow_type,
        parameters: config.parameters,
        frequency: config.frequency,
        next_run: config.next_run || new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      }),
      signal: AbortSignal.timeout(10000) // 10 second timeout
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ detail: 'Unknown error' }));
      console.error('Schedule workflow API error response:', errorData);
      throw new Error(errorData.detail || errorData.error || `Failed to schedule workflow: ${response.status} ${response.statusText}`);
    }

    try {
      const data = await response.json();
      console.log('Schedule workflow API success response:', data);
      return data;
    } catch (parseError) {
      console.error('Error parsing schedule workflow API response:', parseError);
      throw new Error('Failed to parse schedule workflow response');
    }
  } catch (error) {
    console.error('Error scheduling workflow:', error);

    // Check service health
    forceCheckAllServices(); // Re-check service health

    // Create a mock response for graceful degradation
    console.warn('Creating mock schedule response due to error');
    return {
      id: `mock-schedule-${Date.now()}`,
      workflow_type: config.workflow_type,
      parameters: config.parameters,
      frequency: config.frequency,
      next_run: config.next_run || new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      status: 'scheduled',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      user_id: "user-1"
    };
  }
}
