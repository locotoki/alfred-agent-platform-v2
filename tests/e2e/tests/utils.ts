import { Page } from '@playwright/test';

/**
 * Set up mock data mode by intercepting API calls and returning mock responses
 * This is useful for testing UI components without relying on the API
 */
export async function setupMockDataMode(page: Page) {
  // Intercept calls to the niche-scout API endpoint
  await page.route('**/api/social-intel/niche-scout', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
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
      })
    });
  });

  // Intercept calls to the seed-to-blueprint API endpoint
  await page.route('**/api/social-intel/seed-to-blueprint', async route => {
    // Extract the query parameters
    const url = new URL(route.request().url());
    const video_url = url.searchParams.get('video_url') || '';
    const niche = url.searchParams.get('niche') || 'Mobile Gaming';

    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
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
          seed_coverage: Math.random(),
          competitor_coverage: {
            "Mobile60": Math.random(),
            "Mobile55": Math.random(),
            "Mobile50": Math.random()
          },
          opportunity_score: Math.random() * 0.8
        })),
        blueprint: {
          positioning: `A channel focused on ${niche} Tips and Strategy, distinguished by filling the content gap around performance optimization that even top creators like Mobile60 haven't fully covered.`,
          content_pillars: [
            `${niche} Tips & Tricks`,
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
              `${niche} Tips: Deep dive on performance optimization`,
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
              `${niche} Tips: Accessory guide for serious players`,
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
      })
    });
  });
}

/**
 * Wait for the Niche-Scout workflow to complete and verify results
 */
export async function waitForNicheScoutResults(page: Page, timeout = 60000) {
  try {
    // Wait for redirect to results page
    await page.waitForURL(/\/workflows\/niche-scout\/results\//, { timeout });

    // Wait for results to load
    await page.waitForSelector('h1:has-text("NICHE-SCOUT RESULTS")', { timeout: 10000 });

    // Check for visualization or table
    const resultsExist =
      await page.isVisible('.trend-visualization') ||
      await page.isVisible('.trending-niches-table') ||
      await page.isVisible('.niche-visualization');

    return { success: resultsExist, error: null };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

/**
 * Wait for the Seed-to-Blueprint workflow to complete and verify results
 */
export async function waitForBlueprintResults(page: Page, timeout = 90000) {
  try {
    // Wait for redirect to results page
    await page.waitForURL(/\/workflows\/seed-to-blueprint\/results\//, { timeout });

    // Wait for results to load
    await page.waitForSelector('h1:has-text("BLUEPRINT RESULTS")', { timeout: 10000 });

    // Check for blueprint content
    const resultsExist =
      await page.isVisible('.blueprint-section') ||
      await page.isVisible('.content-pillars') ||
      await page.isVisible('.roadmap-section');

    return { success: resultsExist, error: null };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}
