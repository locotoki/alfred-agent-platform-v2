import type { NextApiRequest, NextApiResponse } from 'next';

/**
 * Seed-to-Blueprint API Endpoint
 * 
 * This API proxy forwards requests to the Social Intelligence Agent's Seed-to-Blueprint workflow.
 * It transforms request parameters into the proper A2A envelope format expected by the agent.
 * 
 * Query Parameters:
 * - video_url: URL of a YouTube video to use as seed (required if niche not provided)
 * - niche: Niche keyword to use instead of a seed video (required if video_url not provided)
 * - analysisDepth: Level of analysis depth (optional, defaults to 'Standard')
 *   Options: 'Quick', 'Standard', 'Deep'
 * 
 * Returns:
 * - 200: BlueprintResult object with channel strategy data
 * - 400: Bad request (missing required parameters)
 * - 405: Method not allowed (only POST is supported)
 * - 500: Server error
 */

// Set the URL to the Social Intelligence Agent
const SOCIAL_INTEL_URL = process.env.SOCIAL_INTEL_URL || 'http://localhost:9000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ detail: 'Method not allowed' });
  }

  try {
    // Extract parameters
    const { video_url, niche, analysisDepth } = req.query;

    // Require at least one of video_url or niche
    if (!video_url && !niche) {
      return res.status(400).json({
        detail: 'Either video_url or niche parameter is required',
      });
    }

    // Prepare payload for the Social Intel Agent
    // The agent expects an A2A envelope with the intent YOUTUBE_BLUEPRINT
    const payload = {
      intent: 'YOUTUBE_BLUEPRINT',
      data: {
        seed_url: video_url,
        niche: niche,
        auto_niche: Boolean(niche && !video_url),
        analysisDepth: analysisDepth || 'Standard'
      },
      task_id: `blueprint-${Date.now()}`,
      trace_id: `trace-${Date.now()}`
    };

    // Call the Social Intelligence Agent API
    const response = await fetch(`${SOCIAL_INTEL_URL}/youtube/blueprint`, {
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
        const mockData = {
          run_date: new Date().toISOString(),
          seed_url: video_url || "https://www.youtube.com/watch?v=sample123",
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
            seed_coverage: 1.0,
            competitor_coverage: {
              "Mobile60": Math.random(),
              "Mobile55": Math.random(),
              "Mobile50": Math.random()
            },
            opportunity_score: Math.random() * 0.8
          })),
          blueprint: {
            positioning: "A channel focused on Mobile Gaming Tips and Gaming Strategy, distinguished by filling the content gap around performance optimization that even top creators like Mobile60 haven't fully covered.",
            content_pillars: [
              "Mobile Gaming Tips & Tricks",
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
                "Mobile Gaming Tips: Deep dive on performance optimization",
                "Shorts: Quick tips on game settings",
                "Comparative: Mobile60 vs our approach to Mobile Gaming Tips"
              ],
              "Week 2": [
                "Performance Optimization: Top 10 tips for battery saving",
                "Shorts: One-minute game loading tricks",
                "Livestream Q&A: Answer gaming performance questions"
              ],
              "Week 3": [
                "Industry Updates: New games coming in 2025",
                "Shorts: 30-second review of trending mobile game",
                "Tutorial: How to optimize graphics settings"
              ],
              "Week 4": [
                "Mobile Gaming Tips: Accessory guide for serious gamers",
                "Shorts: Hidden features in popular games",
                "Interview: Professional mobile gamer workflow"
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
          blueprint_url: "#"
        };
        return res.status(200).json(mockData);
      }
      
      const errorData = await response.json();
      console.error('Social Intel API error:', errorData);
      return res.status(response.status).json({
        detail: errorData.detail || 'Failed to process Seed-to-Blueprint workflow',
      });
    }

    // Return the API response
    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    console.error('Error in Seed-to-Blueprint API handler:', error);
    return res.status(500).json({
      detail: error instanceof Error ? error.message : 'Internal server error',
    });
  }
}