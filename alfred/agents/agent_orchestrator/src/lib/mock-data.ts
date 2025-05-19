/**
 * Mock data for YouTube workflows
 */

import {
  NicheScoutResult,
  BlueprintResult,
  WorkflowHistory,
  YouTubeNiche,
  YouTubeVideo,
  YouTubeChannel,
  YouTubeGap,
  YouTubeBlueprint
} from './youtube-service';

/**
 * Mock Niche Scout result
 */
export const mockNicheScoutResult: NicheScoutResult = {
  run_date: new Date().toISOString(),
  trending_niches: Array(20).fill(null).map((_, i) => ({
    query: `trending niche ${i+1}`,
    view_sum: Math.floor(Math.random() * 10000000),
    rsv: Math.random() * 100,
    view_rank: i + 1,
    rsv_rank: Math.floor(Math.random() * 20) + 1,
    score: Math.random() * 100,
    x: Math.random() * 10 - 5,
    y: Math.random() * 10 - 5,
    niche: Math.floor(i / 4)
  } as YouTubeNiche)),
  top_niches: Array(5).fill(null).map((_, i) => ({
    query: `top niche ${i+1}`,
    view_sum: Math.floor(Math.random() * 10000000) + 5000000,
    rsv: Math.random() * 100 + 50,
    view_rank: i + 1,
    rsv_rank: i + 1,
    score: Math.random() * 50 + 50,
    x: Math.random() * 10 - 5,
    y: Math.random() * 10 - 5,
    niche: i
  } as YouTubeNiche)),
  visualization_url: "https://example.com/visualization"
};

/**
 * Mock Blueprint result
 */
export const mockBlueprintResult: BlueprintResult = {
  run_date: new Date().toISOString(),
  seed_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  seed_data: {
    video_id: "dQw4w9WgXcQ",
    title: "Sample YouTube Video",
    channel_id: "UC38IQsAvIsxxjztdMZQtwHA",
    channel_name: "Example Channel",
    view_count: 12345678,
    like_count: 123456,
    comment_count: 9876,
    published_at: "2023-01-15T15:00:00Z",
    duration: "PT8M43S",
    tags: ["example", "sample", "video", "tutorial"],
    description: "This is a sample video description with keywords and information about the content."
  } as YouTubeVideo,
  top_channels: Array(5).fill(null).map((_, i) => ({
    channel_id: `channel-${i+1}`,
    channel_name: `Top Channel ${i+1}`,
    subscribers: Math.floor(Math.random() * 1000000) + 500000,
    total_views: Math.floor(Math.random() * 100000000) + 10000000,
    video_count: Math.floor(Math.random() * 500) + 100,
    recent_upload_count: Math.floor(Math.random() * 20) + 5,
    thirty_day_delta: Math.random() * 5 + 1,
    primary_topics: ["gaming", "tutorials", "reviews", "technology"],
    format_distribution: {
      "long_form": 0.6,
      "shorts": 0.3,
      "livestream": 0.1
    }
  } as YouTubeChannel)),
  gap_analysis: Array(10).fill(null).map((_, i) => ({
    keyword: `keyword ${i+1}`,
    seed_coverage: 1.0,
    competitor_coverage: {
      "Channel 1": Math.random(),
      "Channel 2": Math.random(),
      "Channel 3": Math.random(),
    },
    opportunity_score: Math.random() * 0.8 + 0.2
  } as YouTubeGap)),
  blueprint: {
    positioning: "A channel focused on educational technology tutorials with a focus on beginners, distinguished by clear step-by-step instructions that even top creators haven't fully covered.",
    content_pillars: [
      "Beginner Tutorials",
      "Tech Reviews",
      "Industry News",
      "Q&A Sessions"
    ],
    format_mix: {
      "long_form": 0.6,
      "shorts": 0.3,
      "livestream": 0.1
    },
    roadmap: {
      "Week 1": [
        "Beginner Tutorials: Introduction to the topic",
        "Shorts: Quick tips on getting started",
        "Comparative: Top Channel approach vs our approach"
      ],
      "Week 2": [
        "Tech Reviews: Latest product review",
        "Shorts: 3 quick facts about the product",
        "Tutorial: How to maximize product use"
      ],
      "Week 3": [
        "Industry News: Weekly roundup",
        "Shorts: Breaking news quick take",
        "Deep dive: Analysis of industry trends"
      ],
      "Week 4": [
        "Q&A Session: Live answers to common questions",
        "Shorts: Answering quick questions",
        "Tutorial: Advanced techniques deep dive"
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
        item: "Content appropriate for all ages",
        status: "Required"
      },
      {
        item: "No collection of personal information from children",
        status: "Required"
      },
      {
        item: "Comments disabled if targeting children under 13",
        status: "Required"
      },
      {
        item: "Correct audience setting in YouTube Studio",
        status: "Required"
      },
      {
        item: "No call to actions that lead to external websites",
        status: "Recommended"
      }
    ]
  } as YouTubeBlueprint,
  blueprint_url: "https://example.com/blueprint"
};

/**
 * Mock workflow history
 */
export const mockWorkflowHistory: WorkflowHistory[] = Array(10).fill(null).map((_, i) => ({
  id: `workflow-${i+1}`,
  workflow_type: i % 2 === 0 ? 'niche-scout' : 'seed-to-blueprint',
  parameters: i % 2 === 0
    ? { query: "sample query" }
    : { video_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ" },
  status: ["running", "completed", "completed", "error"][Math.floor(Math.random() * 4)],
  started_at: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
  completed_at: new Date(Date.now() - Math.random() * 6 * 24 * 60 * 60 * 1000).toISOString(),
  result_url: `/workflows/${i % 2 === 0 ? 'niche-scout' : 'seed-to-blueprint'}/results/workflow-${i+1}`,
  user_id: "user-1"
}));
