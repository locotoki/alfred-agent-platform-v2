
export interface IdeaProps {
  title: string;
  description: string;
}

export const IDEAS: IdeaProps[] = [
  {
    title: "Trend Spotlight",
    description: "Analyzes emerging trends in your content niche",
  },
  {
    title: "Audience Pulse",
    description: "Maps audience sentiment and engagement patterns",
  },
  {
    title: "Content Optimizer",
    description: "Suggests optimizations for better engagement",
  },
  {
    title: "Competitor Radar",
    description: "Tracks competitor content strategies and performance",
  },
  {
    title: "Hashtag Analyzer",
    description: "Identifies high-performing hashtags in your niche",
  },
];

export const DEFAULT_CATEGORIES = [
  "Social Media",
  "Content Marketing",
  "Analytics",
  "Audience Research",
  "Engagement",
  "Home Improvement",
  "Health & Wellness",
  "Food & Drink",
  "Technology",
  "Finance"
];

export const DEFAULT_SUBCATEGORIES = {
  "Social Media": ["Instagram", "TikTok", "Twitter", "LinkedIn", "Facebook"],
  "Content Marketing": ["Blog Posts", "Videos", "Podcasts", "Newsletters", "Infographics"],
  "Analytics": ["Performance Metrics", "Growth Tracking", "Conversion Analysis", "ROI Measurement"],
  "Audience Research": ["Demographics", "Behavior Analysis", "Sentiment Analysis", "Surveys"],
  "Engagement": ["Comments", "Shares", "Likes", "Saves", "Click-through"],
  "Home Improvement": ["Sustainable Living", "Interior Design", "DIY Projects", "Smart Home", "Gardening"],
  "Health & Wellness": ["Fitness", "Nutrition", "Mental Health", "Self-Care", "Medical"],
  "Food & Drink": ["Recipes", "Restaurants", "Beverages", "Cooking Tips", "Diet Plans"],
  "Technology": ["Gadgets", "Software", "AI & Machine Learning", "Cybersecurity", "Cloud Computing"],
  "Finance": ["Investment", "Budgeting", "Cryptocurrency", "Real Estate", "Retirement Planning"]
};

export const LANGUAGES = ["English", "Spanish", "French", "German", "Chinese", "Japanese", "Global"];
