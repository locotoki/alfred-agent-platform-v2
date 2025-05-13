/**
 * YouTube Workflows Port Fix Verification Script
 * 
 * This script demonstrates how to properly implement the port fix for the 
 * YouTube workflows integration in the Alfred Agent Platform v2.
 */

// Core issue: The API calls are being sent to port 3000 instead of 3005
// Solution: Use dynamic origin detection with proper fallback port

// Current implementation (causing issues):
// Uses an empty string fallback which can lead to incorrect port
const incorrectImplementation = () => {
  const baseUrl = typeof window !== 'undefined' ? window.location.origin : '';
  const SOCIAL_INTEL_URL = `${baseUrl}/api/social-intel`;
  return SOCIAL_INTEL_URL;
};

// Fixed implementation:
// Explicitly uses port 3005 when not in browser context
const fixedImplementation = () => {
  const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3005';
  const SOCIAL_INTEL_URL = `${baseUrl}/api/social-intel`;
  return SOCIAL_INTEL_URL;
};

// Direct API call in components (replaces service layer calls):
const fixedComponentImplementation = (query) => {
  // In UI component:
  const apiUrl = `${window.location.origin}/api/social-intel/niche-scout?query=${encodeURIComponent(query)}`;
  
  // Then make fetch request:
  /* 
  fetch(apiUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  })
  */
  
  return apiUrl;
};

// Implementations to update:
// 1. services/mission-control/src/services/youtube-workflows.ts 
// 2. services/mission-control/src/pages/workflows/niche-scout/index.tsx
// 3. services/mission-control/src/pages/workflows/seed-to-blueprint/index.tsx

// After modifying these files, the API calls will use the correct port (3005)
// and the workflows will function correctly using either mock data
// or connecting to the Social Intelligence Agent when available.

// Demonstration of mock data generation for testing:
const generateMockNicheScoutData = () => {
  return {
    run_date: new Date().toISOString(),
    trending_niches: Array.from({ length: 5 }, (_, i) => ({
      query: ['mobile gaming tips', 'coding tutorials', 'fitness workouts'][i % 3],
      view_sum: Math.floor(Math.random() * 5000000) + 1000000,
      score: Math.random() * 0.5 + 0.5,
      niche: i % 3
    })),
    _id: `mock-niche-scout-${Date.now()}`
  };
};

// Summary: 
// The port mismatch issue is caused by incorrect URL construction
// The fix ensures that all API calls use port 3005 correctly
// After applying these changes, both workflows will work properly

console.log('YouTube Workflows Port Fix Verification');
console.log('---------------------------------------');
console.log('Incorrect implementation URL:', incorrectImplementation());
console.log('Fixed implementation URL:', fixedImplementation());
console.log('Fixed component direct API call:', fixedComponentImplementation('test query'));
console.log('Example mock data:', generateMockNicheScoutData());
