/**
 * Represents a YouTube niche with trend metrics and visualization coordinates
 */
export interface YouTubeNiche {
  /** The search query that identified this niche */
  query: string;
  /** Sum of views across trending videos in this niche */
  view_sum: number;
  /** Relative search volume score */
  rsv: number;
  /** Rank based on view count (lower is better) */
  view_rank: number;
  /** Rank based on search volume (lower is better) */
  rsv_rank: number;
  /** Combined score (higher is better) */
  score: number;
  /** X-coordinate for visualization plotting */
  x: number;
  /** Y-coordinate for visualization plotting */
  y: number;
  /** Cluster identifier for this niche */
  niche: number;
}

/**
 * Represents a YouTube video with its metadata
 */
export interface YouTubeVideo {
  /** Unique YouTube video ID */
  video_id: string;
  /** Video title */
  title: string;
  /** Channel ID that published the video */
  channel_id: string;
  /** Channel name that published the video */
  channel_name: string;
  /** Number of views on the video */
  view_count: number;
  /** Number of likes on the video (if available) */
  like_count?: number;
  /** Number of comments on the video (if available) */
  comment_count?: number;
  /** Date when the video was published */
  published_at: string;
  /** Video duration in ISO 8601 format */
  duration: string;
  /** Array of video tags */
  tags: string[];
  /** Video description */
  description: string;
}

/**
 * Represents a YouTube channel with analytics data
 */
export interface YouTubeChannel {
  /** Unique YouTube channel ID */
  channel_id: string;
  /** Channel name */
  channel_name: string;
  /** Number of subscribers */
  subscribers: number;
  /** Total view count across all videos */
  total_views: number;
  /** Total number of videos on the channel */
  video_count: number;
  /** Number of uploads in the recent period (usually 30 days) */
  recent_upload_count: number;
  /** Growth rate over the last 30 days (as percentage) */
  thirty_day_delta: number;
  /** Main content topics/categories */
  primary_topics: string[];
  /** Distribution of content formats (e.g., tutorial, review) as percentages */
  format_distribution?: Record<string, number>;
}

/**
 * Represents a content gap opportunity in a niche
 */
export interface YouTubeGap {
  /** The keyword or topic representing a potential content gap */
  keyword: string;
  /** How well the seed channel/video covers this topic (0-100%) */
  seed_coverage: number;
  /** How well competitors cover this topic (channel_id -> coverage percentage) */
  competitor_coverage: Record<string, number>;
  /** Overall score indicating opportunity value (higher is better) */
  opportunity_score: number;
}

/**
 * Strategic blueprint for a YouTube channel
 */
export interface YouTubeBlueprint {
  /** Channel positioning statement */
  positioning: string;
  /** Main content themes/pillars to focus on */
  content_pillars: string[];
  /** Recommended content format distribution (format -> percentage) */
  format_mix: Record<string, number>;
  /** Content roadmap (date/week -> list of content ideas) */
  roadmap: Record<string, string[]>;
  /** AI-generated production tips for the content */
  ai_production_tips: string[];
  /** Children's Online Privacy Protection Act compliance checklist */
  coppa_checklist: Array<{
    /** Checklist item description */
    item: string;
    /** Current status (pass, fail, na) */
    status: string;
  }>;
}

/**
 * Results from the Niche-Scout workflow
 */
export interface NicheScoutResult {
  /** Date when the workflow was executed */
  run_date: string;
  /** Complete list of trending niches discovered */
  trending_niches: YouTubeNiche[];
  /** Top-ranked niches based on combined score */
  top_niches: YouTubeNiche[];
  /** URL to visualization output (if available) */
  visualization_url?: string;
  /** Internal file paths for reports */
  _files?: {
    /** Path to JSON data export */
    json_report: string;
    /** Path to generated report file */
    report_file: string;
  };
  /** Unique ID for the result */
  _id?: string;
  /** Flag indicating this is mock data */
  _mock?: boolean;
  /** Error message explaining why mock data was used */
  _error?: string;
}

/**
 * Results from the Seed-to-Blueprint workflow
 */
export interface BlueprintResult {
  /** Date when the workflow was executed */
  run_date: string;
  /** URL of the seed video that was analyzed */
  seed_url: string;
  /** Metadata of the seed video */
  seed_data: YouTubeVideo;
  /** Top competitor channels in the same niche */
  top_channels: YouTubeChannel[];
  /** Content gap analysis results */
  gap_analysis: YouTubeGap[];
  /** Generated channel blueprint */
  blueprint: YouTubeBlueprint;
  /** URL to the generated blueprint (if available) */
  blueprint_url: string;
  /** Internal file paths for reports */
  _files?: {
    /** Path to JSON data export */
    json_report: string;
    /** Path to generated report file */
    report_file: string;
  };
  /** Unique ID for the result */
  _id?: string;
  /** Flag indicating this is mock data */
  _mock?: boolean;
  /** Error message explaining why mock data was used */
  _error?: string;
}

/**
 * Scheduled workflow configuration
 */
export interface WorkflowSchedule {
  /** Unique identifier for the schedule */
  id: string;
  /** Type of workflow to run */
  workflow_type: 'niche-scout' | 'seed-to-blueprint';
  /** Workflow-specific parameters */
  parameters: Record<string, any>;
  /** How often the workflow should run */
  frequency: 'daily' | 'weekly' | 'monthly' | 'once';
  /** When the workflow is next scheduled to run */
  next_run: string;
  /** Current status of the schedule */
  status: 'scheduled' | 'running' | 'completed' | 'error';
  /** When the schedule was created */
  created_at: string;
  /** When the schedule was last updated */
  updated_at: string;
  /** ID of the user who created the schedule */
  user_id: string;
}

/**
 * Historical record of a workflow execution
 */
export interface WorkflowHistory {
  /** Unique identifier for the workflow run */
  id: string;
  /** Type of workflow that was run */
  workflow_type: 'niche-scout' | 'seed-to-blueprint';
  /** Parameters used for this workflow execution */
  parameters: Record<string, any>;
  /** Current status of the workflow */
  status: 'running' | 'completed' | 'error';
  /** When the workflow execution started */
  started_at: string;
  /** When the workflow execution completed (if finished) */
  completed_at?: string;
  /** URL to access the workflow results */
  result_url?: string;
  /** ID of the user who initiated the workflow */
  user_id: string;
}
