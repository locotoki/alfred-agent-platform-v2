import { createApiUrl, ENDPOINTS, FEATURES } from './api-config';
import { mockNicheScoutResult, mockBlueprintResult, mockWorkflowHistory } from './mock-data';

/**
 * Types for YouTube workflow responses
 */
export interface NicheScoutResult {
  run_date: string;
  trending_niches: YouTubeNiche[];
  top_niches: YouTubeNiche[];
  visualization_url?: string;
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
 * Run the Niche-Scout workflow to find trending YouTube niches
 */
export async function runNicheScout(config: {
  category: string;
  subcategory: string;
  budget?: number;
  dataSources?: Record<string, any>;
}): Promise<NicheScoutResult> {
  // Return mock data if feature flag is enabled
  if (FEATURES.USE_MOCK_DATA) {
    await new Promise(resolve => setTimeout(resolve, 1500));
    return mockNicheScoutResult;
  }

  try {
    const response = await fetch(createApiUrl(ENDPOINTS.NICHE_SCOUT), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(config)
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || error.error || 'Failed to run Niche-Scout workflow');
    }

    return response.json();
  } catch (error) {
    console.error('Error running Niche-Scout workflow:', error);
    // Fall back to mock data if API fails
    return mockNicheScoutResult;
  }
}

/**
 * Run the Seed-to-Blueprint workflow to create a channel strategy
 */
export async function runSeedToBlueprint(params: { video_url?: string; niche?: string; analysisDepth?: string }): Promise<BlueprintResult> {
  // Return mock data if feature flag is enabled
  if (FEATURES.USE_MOCK_DATA) {
    await new Promise(resolve => setTimeout(resolve, 2500));
    return mockBlueprintResult;
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
    const response = await fetch(createApiUrl(ENDPOINTS.SEED_TO_BLUEPRINT, urlParams.toString()), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || error.error || 'Failed to run Seed-to-Blueprint workflow');
    }

    return response.json();
  } catch (error) {
    console.error('Error running Seed-to-Blueprint workflow:', error);
    // Fall back to mock data if API fails
    return mockBlueprintResult;
  }
}

/**
 * Get workflow history
 */
export async function getWorkflowHistory(): Promise<WorkflowHistory[]> {
  // Return mock data if feature flag is enabled
  if (FEATURES.USE_MOCK_DATA) {
    await new Promise(resolve => setTimeout(resolve, 800));
    return mockWorkflowHistory;
  }

  try {
    const response = await fetch(createApiUrl(ENDPOINTS.WORKFLOW_HISTORY), {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || error.error || 'Failed to get workflow history');
    }

    return response.json();
  } catch (error) {
    console.error('Error getting workflow history:', error);
    // Fall back to mock data if API fails
    return mockWorkflowHistory;
  }
}

/**
 * Get workflow result by ID
 */
export async function getWorkflowResult(id: string, type: 'niche-scout' | 'seed-to-blueprint'): Promise<NicheScoutResult | BlueprintResult> {
  // Return mock data if feature flag is enabled
  if (FEATURES.USE_MOCK_DATA) {
    await new Promise(resolve => setTimeout(resolve, 1000));
    return type === 'niche-scout' ? mockNicheScoutResult : mockBlueprintResult;
  }

  const params = new URLSearchParams();
  params.append('type', type);
  
  try {
    const response = await fetch(createApiUrl(`${ENDPOINTS.WORKFLOW_RESULT}/${id}`, params.toString()), {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || error.error || 'Failed to get workflow result');
    }

    return response.json();
  } catch (error) {
    console.error('Error getting workflow result:', error);
    // Fall back to mock data if API fails
    return type === 'niche-scout' ? mockNicheScoutResult : mockBlueprintResult;
  }
}