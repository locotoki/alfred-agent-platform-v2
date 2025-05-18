/**
 * YouTube Workflows Port Fix
 *
 * This script demonstrates the correct approach to connect to the API endpoints
 * when the server is running on port 3005.
 */

// Mock data generation for Niche Scout results
function getMockNicheScoutData() {
  return {
    run_date: new Date().toISOString(),
    trending_niches: Array.from({ length: 20 }, (_, i) => ({
      query: ['mobile gaming tips', 'coding tutorials', 'fitness workouts', 'cooking recipes', 'travel vlogs'][i % 5],
      view_sum: Math.floor(Math.random() * 5000000) + 1000000,
      rsv: Math.random() * 100,
      view_rank: i + 1,
      rsv_rank: i + 1,
      score: Math.random() * 0.5 + 0.5,
      x: Math.random() * 100,
      y: Math.random() * 100,
      niche: i % 5
    })),
    top_niches: Array.from({ length: 10 }, (_, i) => ({
      query: ['mobile gaming tips', 'coding tutorials', 'fitness workouts', 'cooking recipes', 'travel vlogs'][i % 5],
      view_sum: Math.floor(Math.random() * 5000000) + 1000000,
      rsv: Math.random() * 100,
      view_rank: i + 1,
      rsv_rank: i + 1,
      score: Math.random() * 0.5 + 0.5,
      x: Math.random() * 100,
      y: Math.random() * 100,
      niche: i % 5
    })),
    _id: `mock-niche-scout-${Date.now()}`
  };
}

// Mock data generation for Blueprint results
function getMockBlueprintData(niche) {
  return {
    run_date: new Date().toISOString(),
    seed_url: "https://www.youtube.com/watch?v=mock123",
    seed_data: {
      video_id: "mock123",
      title: `Top ${niche || 'Gaming'} Tips for 2025`,
      channel_id: "channel123",
      channel_name: `${niche || 'Gaming'} Pro Channel`,
      view_count: 1500000,
      like_count: 75000,
      comment_count: 8500,
      published_at: "2025-01-15T12:00:00Z",
      duration: "PT15M30S",
      tags: [`${niche || 'gaming'}`, "tips", "strategies", "2025 trends"],
      description: `The best ${niche || 'gaming'} tips for 2025, including recommendations and performance tips.`
    },
    top_channels: Array.from({ length: 10 }, (_, i) => ({
      channel_id: `channel${i + 1}`,
      channel_name: `${niche || 'Gaming'}${60 - i * 5}`,
      subscribers: 5000000 - i * 300000,
      total_views: 250000000 - i * 20000000,
      video_count: 550 - i * 30,
      recent_upload_count: 12 - i % 5,
      thirty_day_delta: Math.random() * 0.2,
      primary_topics: [`${niche || 'gaming'}`, "tips", "reviews", "tutorials", "industry news"]
    })),
    gap_analysis: Array.from({ length: 15 }, (_, i) => ({
      keyword: ["strategy", "tips", "tricks", "performance", "devices", "accessories", "reviews", "tutorials", "industry", "monetization", "streaming", "community"][i % 12],
      seed_coverage: Math.random(),
      competitor_coverage: {
        [`${niche || 'Gaming'}60`]: Math.random(),
        [`${niche || 'Gaming'}55`]: Math.random(),
        [`${niche || 'Gaming'}50`]: Math.random()
      },
      opportunity_score: Math.random() * 0.8
    })),
    blueprint: {
      positioning: `A channel focused on ${niche || 'Gaming'} Tips and Strategy, distinguished by filling the content gap around performance optimization that even top creators haven't fully covered.`,
      content_pillars: [
        `${niche || 'Gaming'} Tips & Tricks`,
        "Performance Optimization",
        "Industry Updates"
      ],
      format_mix: {
        "long_form": 0.6,
        "shorts": 0.3,
        "livestream": 0.1
      },
      roadmap: {
        "Week 1": [
          `${niche || 'Gaming'} Tips: Deep dive on performance optimization`,
          "Shorts: Quick tips on game settings",
          "Comparative: Popular creators vs our approach"
        ],
        "Week 2": [
          "Performance Optimization: Top 10 tips for better results",
          "Shorts: One-minute tricks",
          "Livestream Q&A: Answer performance questions"
        ],
        "Week 3": [
          "Industry Updates: New developments coming in 2025",
          "Shorts: 30-second review of trending item",
          "Tutorial: How to optimize settings"
        ],
        "Week 4": [
          `${niche || 'Gaming'} Tips: Accessory guide for serious players`,
          "Shorts: Hidden features in popular apps",
          "Interview: Professional workflow"
        ]
      },
      ai_production_tips: [
        "Use Whisper API for automatic transcription and subtitles",
        "Stable Diffusion for thumbnail concepts (then refine manually)",
        "Bannerbear API for production-ready thumbnails with templates",
        "GPT-4 for script outlines, focusing on hook, value delivery, CTA",
        "Voice consistency checker to maintain brand tone and style"
      ],
      coppa_checklist: [
        {
          "item": "Content appropriate for all ages",
          "status": "Required"
        },
        {
          "item": "No collection of personal information from children",
          "status": "Required"
        },
        {
          "item": "Comments disabled if targeting children under 13",
          "status": "Required"
        },
        {
          "item": "Correct audience setting in YouTube Studio",
          "status": "Required"
        },
        {
          "item": "No call to actions that lead to external websites",
          "status": "Recommended"
        }
      ]
    },
    blueprint_url: "#",
    _id: `mock-blueprint-${Date.now()}`
  };
}

// Example of direct API calls to port 3005
async function testNicheScout() {
  try {
    // Generate mock data with an ID
    const mockData = getMockNicheScoutData();
    console.log('Mock Niche-Scout data generated with ID:', mockData._id);

    // Use this ID to create a direct URL to the results page
    const resultsUrl = `http://localhost:3005/workflows/niche-scout/results/${mockData._id}?dev_bypass_auth=true`;
    console.log('Direct results URL (Niche-Scout):', resultsUrl);

    return mockData;
  } catch (error) {
    console.error('Error:', error);
  }
}

// Test function for Blueprint workflow
async function testSeedToBlueprint() {
  try {
    // Generate mock data with an ID for Gaming niche
    const mockData = getMockBlueprintData('Gaming');
    console.log('Mock Blueprint data generated with ID:', mockData._id);

    // Use this ID to create a direct URL to the results page
    const resultsUrl = `http://localhost:3005/workflows/seed-to-blueprint/results/${mockData._id}?dev_bypass_auth=true`;
    console.log('Direct results URL (Blueprint):', resultsUrl);

    return mockData;
  } catch (error) {
    console.error('Error:', error);
  }
}

// Call both test functions and log the results
testNicheScout().then(data => console.log('Niche Scout test completed'));
testSeedToBlueprint().then(data => console.log('Blueprint test completed'));

/**
 * Instructions for fixing the port issue:
 *
 * 1. In youtube-workflows.ts:
 *    - Update the baseUrl to explicitly use port 3005 when not in browser:
 *    const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3005';
 *
 * 2. In workflow page components (index.tsx):
 *    - Replace API calls through the service with direct fetch calls using window.location.origin:
 *    const apiUrl = `${window.location.origin}/api/social-intel/niche-scout?query=${encodeURIComponent(query)}`;
 *
 * 3. Mock data fallback:
 *    - Ensure all API handlers have robust mock data generation for testing
 */
