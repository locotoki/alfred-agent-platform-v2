import type { NextApiRequest, NextApiResponse } from 'next';

/**
 * Helper utility to handle API proxying and mock data generation
 * This ensures that requests to either port 3000 or 3005 work correctly
 */

// In production Docker environment, use http://social-intel:9000
// In development, use http://localhost:9000
export const SOCIAL_INTEL_URL = process.env.SOCIAL_INTEL_URL || process.env.SOCIAL_INTEL_SERVICE_URL || 'http://localhost:9000';

/**
 * Generate mock data for Niche Scout results
 */
export function getMockNicheScoutData() {
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

/**
 * Generate mock data for Blueprint results
 */
export function getMockBlueprintData(niche?: string, video_url?: string) {
  return {
    run_date: new Date().toISOString(),
    seed_url: video_url ? video_url : "https://www.youtube.com/watch?v=sample123",
    seed_data: {
      video_id: "sample123",
      title: "Top Mobile Gaming Tips for 2025",
      channel_id: "channel123",
      channel_name: "Mobile Gaming Pro",
      view_count: 1500000,
      like_count: 75000,
      comment_count: 8500,
      published_at: "2025-01-15T12:00:00Z",
      duration: "PT15M30S",
      tags: ["mobile gaming", "gaming tips", "mobile games", "2025 gaming"],
      description: "The best mobile gaming tips for 2025, including new game recommendations and performance tips."
    },
    top_channels: Array.from({ length: 10 }, (_, i) => ({
      channel_id: `channel${i + 1}`,
      channel_name: `Mobile${60 - i * 5}`,
      subscribers: 5000000 - i * 300000,
      total_views: 250000000 - i * 20000000,
      video_count: 550 - i * 30,
      recent_upload_count: 12 - i % 5,
      thirty_day_delta: Math.random() * 0.2,
      primary_topics: ["mobile gaming", "gaming tips", "game reviews", "tutorials", "industry news"]
    })),
    gap_analysis: Array.from({ length: 15 }, (_, i) => ({
      keyword: ["mobile", "gaming", "tips", "strategy", "tricks", "performance", "devices", "accessories", "reviews", "tutorials", "industry", "esports", "monetization", "streaming", "community"][i],
      seed_coverage: Math.random(),
      competitor_coverage: {
        "Mobile60": Math.random(),
        "Mobile55": Math.random(),
        "Mobile50": Math.random()
      },
      opportunity_score: Math.random() * 0.8
    })),
    blueprint: {
      positioning: `A channel focused on ${niche || 'Mobile Gaming'} Tips and Strategy, distinguished by filling the content gap around performance optimization that even top creators like Mobile60 haven't fully covered.`,
      content_pillars: [
        `${niche || 'Mobile Gaming'} Tips & Tricks`,
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
          `${niche || 'Mobile Gaming'} Tips: Deep dive on performance optimization`,
          "Shorts: Quick tips on game settings",
          "Comparative: Mobile60 vs our approach to Gaming Tips"
        ],
        "Week 2": [
          "Performance Optimization: Top 10 tips for battery saving",
          "Shorts: One-minute game loading tricks",
          "Livestream Q&A: Answer performance questions"
        ],
        "Week 3": [
          "Industry Updates: New developments coming in 2025",
          "Shorts: 30-second review of trending item",
          "Tutorial: How to optimize settings"
        ],
        "Week 4": [
          `${niche || 'Mobile Gaming'} Tips: Accessory guide for serious players`,
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

/**
 * Check if we need to use mock data based on the error
 */
export function useMockData(error: any): boolean {
  // Determine if we should use mock data based on error type
  return (
    error instanceof TypeError ||
    (error instanceof Error && error.message.includes('fetch')) ||
    (error instanceof Error && error.message.includes('network')) ||
    (error instanceof Error && error.message.includes('timeout')) ||
    (error instanceof Error && error.message.includes('404'))
  );
}
