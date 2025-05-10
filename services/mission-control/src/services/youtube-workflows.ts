import { NicheScoutResult, BlueprintResult, WorkflowHistory, WorkflowSchedule, YouTubeNiche, YouTubeChannel, YouTubeGap } from '../types/youtube-workflows';

// Use local API proxy to avoid CORS issues
// Include the current hostname and port to ensure we call the right endpoint
// This dynamic detection ensures the service works in any environment
// Force use of current window origin to avoid hardcoded port issues
// Dynamically use the current server's port rather than hardcoding any specific port
const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3007';
const SOCIAL_INTEL_URL = `${baseUrl}/api/social-intel`;

console.log('Using API URL:', SOCIAL_INTEL_URL);

// Mock data for development and fallbacks when API is unavailable
export const mockNicheScoutResult: NicheScoutResult = {
  run_date: new Date().toISOString(),
  trending_niches: Array(20).fill(null).map((_, i) => ({
    query: `trending niche ${i+1}`,
    view_sum: 100000 + i * 10000,
    rsv: 0.8 - (i * 0.02),
    view_rank: i + 1,
    rsv_rank: i + 1,
    score: 0.9 - (i * 0.03),
    x: Math.random() * 100,
    y: Math.random() * 100,
    niche: Math.floor(i / 5) + 1,
  })),
  top_niches: Array(5).fill(null).map((_, i) => ({
    query: `top niche ${i+1}`,
    view_sum: 500000 - i * 50000,
    rsv: 0.95 - (i * 0.05),
    view_rank: i + 1,
    rsv_rank: i + 1,
    score: 0.95 - (i * 0.05),
    x: Math.random() * 100,
    y: Math.random() * 100,
    niche: i + 1,
  })),
  visualization_url: 'https://example.com/visualization',
  _id: `niche-scout-${Date.now()}`
};

export const mockBlueprintResult: BlueprintResult = {
  run_date: new Date().toISOString(),
  seed_url: 'https://youtube.com/watch?v=dQw4w9WgXcQ',
  seed_data: {
    video_id: 'dQw4w9WgXcQ',
    title: 'Sample Video Title',
    channel_id: 'UC-sample',
    channel_name: 'Sample Channel',
    view_count: 1000000,
    like_count: 50000,
    comment_count: 5000,
    published_at: '2023-01-01T00:00:00Z',
    duration: 'PT5M30S',
    tags: ['sample', 'demo', 'tutorial'],
    description: 'This is a sample video description.'
  },
  top_channels: Array(5).fill(null).map((_, i) => ({
    channel_id: `UC-channel-${i+1}`,
    channel_name: `Top Channel ${i+1}`,
    subscribers: 1000000 - i * 100000,
    total_views: 50000000 - i * 5000000,
    video_count: 500 - i * 50,
    recent_upload_count: 30 - i * 5,
    thirty_day_delta: 5 - i * 0.5,
    primary_topics: ['Topic A', 'Topic B', 'Topic C']
  })),
  gap_analysis: Array(5).fill(null).map((_, i) => ({
    keyword: `Gap Keyword ${i+1}`,
    seed_coverage: 0.2 + i * 0.1,
    competitor_coverage: {
      'channel-1': 0.5,
      'channel-2': 0.3,
      'channel-3': 0.7
    },
    opportunity_score: 0.9 - i * 0.1
  })),
  blueprint: {
    positioning: 'Sample channel positioning statement',
    content_pillars: ['Main Topic A', 'Main Topic B', 'Main Topic C'],
    format_mix: {
      'Tutorials': 0.4,
      'Reviews': 0.3,
      'Vlogs': 0.2,
      'Shorts': 0.1
    },
    roadmap: {
      'Week 1': ['Content idea 1', 'Content idea 2'],
      'Week 2': ['Content idea 3', 'Content idea 4'],
      'Week 3': ['Content idea 5', 'Content idea 6'],
      'Week 4': ['Content idea 7', 'Content idea 8']
    },
    ai_production_tips: [
      'Use good lighting',
      'Script your videos',
      'Optimize thumbnails',
      'Engage with comments'
    ],
    coppa_checklist: [
      { item: 'Content suitable for all ages', status: 'pass' },
      { item: 'No personal information collection', status: 'pass' }
    ]
  },
  blueprint_url: 'https://example.com/blueprint',
  _id: `blueprint-${Date.now()}`
};

export const mockWorkflowHistory: WorkflowHistory[] = Array(5).fill(null).map((_, i) => ({
  id: `workflow-${i+1}`,
  workflow_type: i % 2 === 0 ? 'niche-scout' : 'seed-to-blueprint',
  parameters: { query: 'sample query' },
  status: i === 0 ? 'running' : 'completed',
  started_at: new Date(Date.now() - i * 86400000).toISOString(),
  completed_at: i === 0 ? undefined : new Date(Date.now() - i * 86400000 + 3600000).toISOString(),
  result_url: i === 0 ? undefined : '/results/sample-result',
  user_id: 'user-1'
}));

// Define common timeout durations for different operations
const TIMEOUT_SHORT = 30000;  // 30 seconds for simple operations
const TIMEOUT_MEDIUM = 60000; // 60 seconds for medium complexity
const TIMEOUT_LONG = 120000;  // 120 seconds for complex operations

/**
 * Run the Niche-Scout workflow to find trending YouTube niches
 */
export async function runNicheScout(query?: string): Promise<NicheScoutResult> {
  const params = new URLSearchParams();
  if (query) {
    params.append('query', query);
  }

  try {
    // Log the request
    console.log(`Running Niche-Scout workflow with query: ${query || 'none'}`);
    
    // Multiple endpoint paths to try - sometimes the service might use different endpoint structures
    const endpoints = [
      `${SOCIAL_INTEL_URL}/niche-scout`, 
      `${SOCIAL_INTEL_URL}/youtube/niche-scout`,
      `${SOCIAL_INTEL_URL}/api/youtube/niche-scout`
    ];
    
    let response = null;
    let lastError = null;
    
    // Try each endpoint until one works
    for (const endpoint of endpoints) {
      try {
        response = await fetch(`${endpoint}?${params.toString()}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          // Add timeout to prevent hanging requests
          signal: AbortSignal.timeout(45000) // 45 second timeout - some complex queries might take longer
        });
        
        // If successful, break out of the loop
        if (response.ok) {
          break;
        }
      } catch (err) {
        // Keep track of the last error
        lastError = err;
        console.warn(`Failed to connect to endpoint ${endpoint}:`, err);
        // Continue to next endpoint
      }
    }
    
    // If we got a valid response
    if (response && response.ok) {
      const data = await response.json();
      
      // Ensure the result has an ID field for result page navigation
      if (!data._id) {
        data._id = `niche-scout-${Date.now()}`;
      }
      
      return data;
    }
    
    // If response exists but is not OK
    if (response) {
      console.warn('All endpoints returned non-OK response, falling back to mock data');
      return {
        ...mockNicheScoutResult, 
        _id: `niche-scout-${Date.now()}`,
        _mock: true, // Flag to indicate this is mock data
        _error: "API returned an error, showing mock data instead"
      };
    }
    
    // If no response at all
    console.warn('Could not connect to any Social Intelligence Agent endpoints, falling back to mock data');
    return {
      ...mockNicheScoutResult, 
      _id: `niche-scout-${Date.now()}`,
      _mock: true, // Flag to indicate this is mock data
      _error: "Could not connect to API, showing mock data instead"
    };
  } catch (error) {
    console.error('Error running Niche-Scout workflow:', error);
    console.warn('Returning mock data due to error');
    return {
      ...mockNicheScoutResult, 
      _id: `niche-scout-${Date.now()}`,
      _mock: true, // Flag to indicate this is mock data
      _error: "Error connecting to API, showing mock data instead"
    };
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
    // Log the request
    console.log(`Running Seed-to-Blueprint workflow with params:`, params);
    
    // Multiple endpoint paths to try - sometimes the service might use different endpoint structures
    const endpoints = [
      `${SOCIAL_INTEL_URL}/seed-to-blueprint`, 
      `${SOCIAL_INTEL_URL}/youtube/blueprint`,
      `${SOCIAL_INTEL_URL}/api/youtube/blueprint`
    ];
    
    let response = null;
    let lastError = null;
    
    // Try each endpoint until one works
    for (const endpoint of endpoints) {
      try {
        response = await fetch(`${endpoint}?${urlParams.toString()}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          // Add timeout to prevent hanging requests
          signal: AbortSignal.timeout(90000) // 90 second timeout for this more complex workflow
        });
        
        // If successful, break out of the loop
        if (response.ok) {
          break;
        }
      } catch (err) {
        // Keep track of the last error
        lastError = err;
        console.warn(`Failed to connect to endpoint ${endpoint}:`, err);
        // Continue to next endpoint
      }
    }
    
    // If we got a valid response
    if (response && response.ok) {
      const data = await response.json();
      
      // Ensure the result has an ID field for result page navigation
      if (!data._id) {
        data._id = `blueprint-${Date.now()}`;
      }
      
      return data;
    }
    
    // If response exists but is not OK
    if (response) {
      console.warn('All endpoints returned non-OK response, falling back to mock data');
      return {
        ...mockBlueprintResult, 
        _id: `blueprint-${Date.now()}`,
        _mock: true, // Flag to indicate this is mock data
        _error: "API returned an error, showing mock data instead"
      };
    }
    
    // If no response at all
    console.warn('Could not connect to any Social Intelligence Agent endpoints, falling back to mock data');
    return {
      ...mockBlueprintResult, 
      _id: `blueprint-${Date.now()}`,
      _mock: true, // Flag to indicate this is mock data
      _error: "Could not connect to API, showing mock data instead"
    };
  } catch (error) {
    console.error('Error running Seed-to-Blueprint workflow:', error);
    console.warn('Returning mock data due to error');
    return {
      ...mockBlueprintResult, 
      _id: `blueprint-${Date.now()}`,
      _mock: true, // Flag to indicate this is mock data
      _error: "Error connecting to API, showing mock data instead"
    };
  }
}

/**
 * Get workflow history
 */
export async function getWorkflowHistory(): Promise<WorkflowHistory[]> {
  try {
    console.log('Fetching workflow history from:', `${SOCIAL_INTEL_URL}/workflow-history`);
    
    // Try multiple endpoints for better resilience
    const endpoints = [
      `${SOCIAL_INTEL_URL}/workflow-history`,
      `${SOCIAL_INTEL_URL}/youtube/workflow-history`,
      `${SOCIAL_INTEL_URL}/api/youtube/workflow-history`,
    ];
    
    let response = null;
    let lastError = null;
    
    // Try each endpoint until one works
    for (const endpoint of endpoints) {
      try {
        response = await fetch(endpoint, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          signal: AbortSignal.timeout(30000) // 30 second timeout
        });
        
        if (response.ok) {
          console.log(`Successfully called workflow history endpoint: ${endpoint}`);
          break;
        }
      } catch (err) {
        console.warn(`Failed to connect to endpoint ${endpoint}:`, err);
        lastError = err;
      }
    }
    
    if (!response || !response.ok) {
      console.warn('All workflow history endpoints failed, returning empty array');
      return []; // Return empty array instead of throwing error
    }
    
    const data = await response.json();
    return Array.isArray(data) ? data : [];
  } catch (error) {
    console.error('Error in getWorkflowHistory:', error);
    return []; // Return empty array on error
  }
}

/**
 * Get scheduled workflows
 */
export async function getScheduledWorkflows(): Promise<WorkflowSchedule[]> {
  try {
    console.log('Fetching scheduled workflows from:', `${SOCIAL_INTEL_URL}/scheduled-workflows`);
    
    // Try multiple endpoints for better resilience
    const endpoints = [
      `${SOCIAL_INTEL_URL}/scheduled-workflows`,
      `${SOCIAL_INTEL_URL}/youtube/scheduled-workflows`,
      `${SOCIAL_INTEL_URL}/api/youtube/scheduled-workflows`,
    ];
    
    let response = null;
    let lastError = null;
    
    // Try each endpoint until one works
    for (const endpoint of endpoints) {
      try {
        response = await fetch(endpoint, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          signal: AbortSignal.timeout(30000) // 30 second timeout
        });
        
        if (response.ok) {
          console.log(`Successfully called scheduled workflows endpoint: ${endpoint}`);
          break;
        }
      } catch (err) {
        console.warn(`Failed to connect to endpoint ${endpoint}:`, err);
        lastError = err;
      }
    }
    
    if (!response || !response.ok) {
      console.warn('All scheduled workflows endpoints failed, returning empty array');
      return []; // Return empty array instead of throwing error
    }
    
    const data = await response.json();
    return Array.isArray(data) ? data : [];
  } catch (error) {
    console.error('Error in getScheduledWorkflows:', error);
    return []; // Return empty array on error
  }
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
  try {
    console.log('Scheduling workflow:', data);
    
    // Multiple endpoint paths to try
    const endpoints = [
      `${SOCIAL_INTEL_URL}/schedule-workflow`,
      `${SOCIAL_INTEL_URL}/youtube/schedule-workflow`,
      `${SOCIAL_INTEL_URL}/api/youtube/schedule-workflow`
    ];
    
    let response = null;
    let lastError = null;
    
    // Try each endpoint until one works
    for (const endpoint of endpoints) {
      try {
        response = await fetch(endpoint, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(data),
          signal: AbortSignal.timeout(30000) // 30 second timeout
        });
        
        if (response.ok) {
          break;
        }
      } catch (err) {
        lastError = err;
        console.warn(`Failed to connect to endpoint ${endpoint}:`, err);
      }
    }
    
    if (response && response.ok) {
      return await response.json();
    }
    
    // Create a mock successful response
    console.warn('Failed to schedule workflow, returning mock success response');
    return {
      id: `scheduled-${Date.now()}`,
      workflow_type: data.workflow_type,
      parameters: data.parameters,
      frequency: data.frequency,
      next_run: data.next_run,
      status: 'scheduled',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      user_id: 'current-user'
    };
  } catch (error) {
    console.error('Error scheduling workflow:', error);
    
    // Return a mock successful response instead of throwing
    return {
      id: `scheduled-${Date.now()}`,
      workflow_type: data.workflow_type,
      parameters: data.parameters,
      frequency: data.frequency,
      next_run: data.next_run,
      status: 'scheduled',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      user_id: 'current-user'
    };
  }
}

/**
 * Get workflow result by ID
 */
export async function getWorkflowResult(id: string, type: 'niche-scout' | 'seed-to-blueprint'): Promise<NicheScoutResult | BlueprintResult> {
  try {
    // Log the request
    console.log(`Getting ${type} workflow result with ID: ${id}`);
    
    // Multiple endpoint paths to try
    const endpoints = [
      `${SOCIAL_INTEL_URL}/workflow-result/${id}`,
      `${SOCIAL_INTEL_URL}/youtube/workflow-result/${id}`,
      `${SOCIAL_INTEL_URL}/api/youtube/workflow-result/${id}`
    ];
    
    let response = null;
    let lastError = null;
    
    // Try each endpoint until one works
    for (const endpoint of endpoints) {
      try {
        response = await fetch(`${endpoint}?type=${type}`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          // Add timeout to prevent hanging requests
          signal: AbortSignal.timeout(30000)
        });
        
        // If successful, break out of the loop
        if (response.ok) {
          break;
        }
      } catch (err) {
        // Keep track of the last error
        lastError = err;
        console.warn(`Failed to connect to endpoint ${endpoint}:`, err);
        // Continue to next endpoint
      }
    }
    
    // If we got a valid response
    if (response && response.ok) {
      const data = await response.json();
      
      // If the result has no ID field, add it
      if (!data._id) {
        data._id = id;
      }
      
      return data;
    }
    
    // If response exists but is not OK
    if (response) {
      console.warn(`Failed to get ${type} workflow result, falling back to mock data`);
      return type === 'niche-scout' 
        ? {
            ...mockNicheScoutResult, 
            _id: id,
            _mock: true, 
            _error: "API returned an error, showing mock data instead"
          } 
        : {
            ...mockBlueprintResult, 
            _id: id,
            _mock: true, 
            _error: "API returned an error, showing mock data instead"
          };
    }
    
    // If no response at all
    console.warn('Could not connect to any Social Intelligence Agent endpoints, falling back to mock data');
    return type === 'niche-scout' 
      ? {
          ...mockNicheScoutResult, 
          _id: id,
          _mock: true, 
          _error: "Could not connect to API, showing mock data instead"
        } 
      : {
          ...mockBlueprintResult, 
          _id: id,
          _mock: true, 
          _error: "Could not connect to API, showing mock data instead"
        };
  } catch (error) {
    console.error(`Error getting ${type} workflow result:`, error);
    console.warn('Returning mock data due to error');
    return type === 'niche-scout' 
      ? {
          ...mockNicheScoutResult, 
          _id: id,
          _mock: true, 
          _error: "Error connecting to API, showing mock data instead"
        } 
      : {
          ...mockBlueprintResult, 
          _id: id,
          _mock: true, 
          _error: "Error connecting to API, showing mock data instead"
        };
  }
}