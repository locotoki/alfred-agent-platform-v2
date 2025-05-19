import {
  NicheScoutResult,
  BlueprintResult,
  WorkflowHistory,
  WorkflowSchedule
} from '../../../types/youtube-workflows';

export const mockNicheScoutResult: NicheScoutResult = {
  run_date: '2025-05-06T10:30:00Z',
  trending_niches: [
    {
      query: 'gaming',
      view_sum: 1500000,
      rsv: 95,
      view_rank: 1,
      rsv_rank: 2,
      score: 89,
      x: 0.7,
      y: 0.8,
      niche: 1
    },
    {
      query: 'cooking',
      view_sum: 750000,
      rsv: 82,
      view_rank: 3,
      rsv_rank: 4,
      score: 76,
      x: 0.5,
      y: 0.6,
      niche: 2
    },
    {
      query: 'fitness',
      view_sum: 1200000,
      rsv: 89,
      view_rank: 2,
      rsv_rank: 3,
      score: 83,
      x: 0.6,
      y: 0.7,
      niche: 3
    }
  ],
  top_niches: [
    {
      query: 'gaming',
      view_sum: 1500000,
      rsv: 95,
      view_rank: 1,
      rsv_rank: 2,
      score: 89,
      x: 0.7,
      y: 0.8,
      niche: 1
    },
    {
      query: 'fitness',
      view_sum: 1200000,
      rsv: 89,
      view_rank: 2,
      rsv_rank: 3,
      score: 83,
      x: 0.6,
      y: 0.7,
      niche: 3
    }
  ],
  visualization_url: '/mock-data/niche-chart.png',
  _files: {
    json_report: '/mock-data/niche-scout-report.json',
    report_file: '/mock-data/niche-scout-report.pdf'
  }
};

export const mockBlueprintResult: BlueprintResult = {
  run_date: '2025-05-06T11:45:00Z',
  seed_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  seed_data: {
    video_id: 'dQw4w9WgXcQ',
    title: 'Sample Video Title',
    channel_id: 'UC-sample123',
    channel_name: 'Sample Channel',
    view_count: 500000,
    like_count: 35000,
    comment_count: 2500,
    published_at: '2025-05-01T09:00:00Z',
    duration: 'PT8M43S',
    tags: ['gaming', 'tips', 'strategy'],
    description: 'This is a sample video description for testing purposes.'
  },
  top_channels: [
    {
      channel_id: 'UC-top1',
      channel_name: 'Top Gaming Channel',
      subscribers: 2500000,
      total_views: 150000000,
      video_count: 450,
      recent_upload_count: 12,
      thirty_day_delta: 50000,
      primary_topics: ['gaming', 'tutorials', 'reviews']
    },
    {
      channel_id: 'UC-top2',
      channel_name: 'Pro Gamer Tips',
      subscribers: 1800000,
      total_views: 95000000,
      video_count: 320,
      recent_upload_count: 8,
      thirty_day_delta: 30000,
      primary_topics: ['gaming', 'strategy', 'esports']
    }
  ],
  gap_analysis: [
    {
      keyword: 'beginner gaming',
      seed_coverage: 0.2,
      competitor_coverage: {
        'Top Gaming Channel': 0.4,
        'Pro Gamer Tips': 0.3
      },
      opportunity_score: 85
    },
    {
      keyword: 'game walkthroughs',
      seed_coverage: 0.1,
      competitor_coverage: {
        'Top Gaming Channel': 0.7,
        'Pro Gamer Tips': 0.5
      },
      opportunity_score: 92
    }
  ],
  blueprint: {
    positioning: 'Accessible gaming tutorials focused on beginners with expert tips',
    content_pillars: ['Game tutorials', 'Strategy guides', 'Beginner tips', 'Game reviews'],
    format_mix: {
      'Tutorials': 40,
      'Reviews': 30,
      'Let\'s Play': 20,
      'Tier lists': 10
    },
    roadmap: {
      'Month 1': ['Channel intro', 'Top 10 beginner tips', 'First tutorial series'],
      'Month 2': ['Review series', 'Expert guest', 'Strategy deep-dive'],
      'Month 3': ['Community Q&A', 'Advanced tutorial', 'Tier list series']
    },
    ai_production_tips: [
      'Use AI for script generation',
      'Create thumbnails with consistent branding',
      'Maintain posting schedule of 3 videos per week'
    ],
    coppa_checklist: [
      { item: 'Content suitable for general audiences', status: 'Passed' },
      { item: 'No excessive profanity', status: 'Passed' },
      { item: 'Not directed primarily at children', status: 'Passed' }
    ]
  },
  blueprint_url: '/mock-data/blueprint-report.pdf',
  _files: {
    json_report: '/mock-data/blueprint-result.json',
    report_file: '/mock-data/blueprint-report.pdf'
  }
};

export const mockWorkflowHistory: WorkflowHistory[] = [
  {
    id: 'wh-123',
    workflow_type: 'niche-scout',
    parameters: { query: 'gaming' },
    status: 'completed',
    started_at: '2025-05-05T10:00:00Z',
    completed_at: '2025-05-05T10:15:00Z',
    result_url: '/mock-data/niche-scout-report.pdf',
    user_id: 'user-1'
  },
  {
    id: 'wh-124',
    workflow_type: 'seed-to-blueprint',
    parameters: { niche: 'gaming' },
    status: 'completed',
    started_at: '2025-05-05T11:00:00Z',
    completed_at: '2025-05-05T11:30:00Z',
    result_url: '/mock-data/blueprint-report.pdf',
    user_id: 'user-1'
  },
  {
    id: 'wh-125',
    workflow_type: 'niche-scout',
    parameters: { query: 'cooking' },
    status: 'completed',
    started_at: '2025-05-05T14:00:00Z',
    completed_at: '2025-05-05T14:15:00Z',
    result_url: '/mock-data/niche-scout-report-cooking.pdf',
    user_id: 'user-1'
  },
  {
    id: 'wh-126',
    workflow_type: 'seed-to-blueprint',
    parameters: { niche: 'fitness' },
    status: 'completed',
    started_at: '2025-05-04T09:00:00Z',
    completed_at: '2025-05-04T09:30:00Z',
    result_url: '/mock-data/blueprint-report-fitness.pdf',
    user_id: 'user-1'
  }
];

export const mockScheduledWorkflows: WorkflowSchedule[] = [
  {
    id: 'sched-123',
    workflow_type: 'niche-scout',
    parameters: { query: 'gaming' },
    frequency: 'daily',
    next_run: '2025-05-07T10:00:00Z',
    status: 'scheduled',
    created_at: '2025-05-05T09:00:00Z',
    updated_at: '2025-05-05T09:00:00Z',
    user_id: 'user-1'
  },
  {
    id: 'sched-124',
    workflow_type: 'seed-to-blueprint',
    parameters: { niche: 'fitness' },
    frequency: 'weekly',
    next_run: '2025-05-12T10:00:00Z',
    status: 'scheduled',
    created_at: '2025-05-05T09:30:00Z',
    updated_at: '2025-05-05T09:30:00Z',
    user_id: 'user-1'
  },
  {
    id: 'sched-125',
    workflow_type: 'niche-scout',
    parameters: { query: 'cooking' },
    frequency: 'once',
    next_run: '2025-05-08T10:00:00Z',
    status: 'scheduled',
    created_at: '2025-05-05T10:00:00Z',
    updated_at: '2025-05-05T10:00:00Z',
    user_id: 'user-1'
  }
];
