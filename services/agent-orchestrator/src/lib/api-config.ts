/**
 * API Configuration
 * 
 * This file contains configuration settings for API endpoints.
 * It uses environment variables for different environments.
 */

// Get API URLs from environment variables
export const SOCIAL_INTEL_URL = import.meta.env.VITE_SOCIAL_INTEL_URL || 'http://localhost:9000';
export const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:9000';

// Feature flags
export const FEATURES = {
  // Enable this to use mock data instead of real API
  USE_MOCK_DATA: import.meta.env.VITE_USE_MOCK_DATA === 'true',
  
  // Enable this to show developer tools
  SHOW_DEV_TOOLS: import.meta.env.NODE_ENV === 'development'
};

// Delay for mock responses (to simulate network latency)
export const MOCK_DELAY_MS = 1000;

// API endpoints
export const ENDPOINTS = {
  // YouTube workflows
  NICHE_SCOUT: `${API_BASE_URL}/api/youtube/niche-scout`,
  SEED_TO_BLUEPRINT: `${API_BASE_URL}/api/youtube/seed-to-blueprint`,
  WORKFLOW_HISTORY: `${API_BASE_URL}/api/youtube/workflow-history`,
  WORKFLOW_RESULT: `${API_BASE_URL}/api/youtube/workflow-result`,
  SCHEDULED_WORKFLOWS: `${API_BASE_URL}/api/youtube/scheduled-workflows`,
  SCHEDULE_WORKFLOW: `${API_BASE_URL}/api/youtube/schedule-workflow`,
  
  // Agent operations
  AGENTS_LIST: `${API_BASE_URL}/api/agents`,
  AGENT_STATUS: `${API_BASE_URL}/api/agents/status`,
  AGENT_CONTROL: `${API_BASE_URL}/api/agents/control`,
  
  // Health check
  HEALTH: `${API_BASE_URL}/health`
};

/**
 * Helper to create an API URL
 */
export function createApiUrl(endpoint: string, params: string = ''): string {
  if (params) {
    return `${endpoint}?${params}`;
  }
  
  return endpoint;
}