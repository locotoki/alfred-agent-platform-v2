
export interface Agent {
  id: string;
  name: string;
  status: "active" | "idle" | "error" | "offline";
  version: string;
  lastTask: Date | null;
  queueLag: number;
  description: string;
  type: "social-intel" | "legal-compliance" | "financial-tax" | "content-calendar";
}

export interface Workflow {
  id: string;
  name: string;
  description: string;
  frequency: "hourly" | "daily" | "weekly" | "monthly" | "custom";
  timeOfDay?: string; // HH:mm format
  lastRun?: Date;
  nextRun?: Date;
  status: "active" | "paused" | "error";
  agentId: string;
}

export const agents: Agent[] = [
  {
    id: "agent-1",
    name: "Social-Intel",
    status: "active",
    version: "2.4.1",
    lastTask: new Date(Date.now() - 3 * 60 * 1000), // 3 minutes ago
    queueLag: 23,
    description: "Analyzes social media trends and audience insights",
    type: "social-intel"
  },
  {
    id: "agent-2",
    name: "Legal-Compliance",
    status: "idle",
    version: "1.8.3",
    lastTask: new Date(Date.now() - 45 * 60 * 1000), // 45 minutes ago
    queueLag: 0,
    description: "Monitors content for regulatory compliance issues",
    type: "legal-compliance"
  },
  {
    id: "agent-3",
    name: "Financial-Tax",
    status: "active",
    version: "3.1.0",
    lastTask: new Date(Date.now() - 12 * 60 * 1000), // 12 minutes ago
    queueLag: 5,
    description: "Analyzes financial data and prepares tax reports",
    type: "financial-tax"
  },
  {
    id: "agent-4",
    name: "Content-Calendar",
    status: "error",
    version: "1.2.1",
    lastTask: new Date(Date.now() - 120 * 60 * 1000), // 2 hours ago
    queueLag: 156,
    description: "Manages content scheduling across multiple platforms",
    type: "content-calendar"
  },
  {
    id: "agent-5",
    name: "Audience-Insights",
    status: "offline",
    version: "0.9.4",
    lastTask: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
    queueLag: 0,
    description: "Analyzes audience demographics and behaviors",
    type: "social-intel"
  }
];

export const socialIntelWorkflows: Workflow[] = [
  {
    id: "workflow-1",
    name: "Niche-Scout",
    description: "Identifies emerging content niches and trending topics",
    frequency: "daily",
    timeOfDay: "09:00",
    lastRun: new Date(Date.now() - 18 * 60 * 60 * 1000),
    nextRun: new Date(Date.now() + 6 * 60 * 60 * 1000),
    status: "active",
    agentId: "agent-1"
  },
  {
    id: "workflow-2",
    name: "Seed-to-Blueprint",
    description: "Transforms content ideas into structured content plans",
    frequency: "weekly",
    timeOfDay: "10:00",
    lastRun: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    nextRun: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000),
    status: "active",
    agentId: "agent-1"
  },
  {
    id: "workflow-3",
    name: "Sponsor-Market Pulse",
    description: "Analyzes sponsorship opportunities and market rates",
    frequency: "weekly",
    timeOfDay: "14:00",
    lastRun: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000),
    nextRun: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000),
    status: "active",
    agentId: "agent-1"
  },
  {
    id: "workflow-4",
    name: "Audience-Sentiment Miner",
    description: "Analyzes audience sentiment across content and platforms",
    frequency: "daily",
    timeOfDay: "15:00",
    lastRun: new Date(Date.now() - 20 * 60 * 60 * 1000),
    nextRun: new Date(Date.now() + 4 * 60 * 60 * 1000),
    status: "active",
    agentId: "agent-1"
  },
  {
    id: "workflow-5",
    name: "Retention Heat-Fingerprinting",
    description: "Identifies viewer retention patterns and drop-off points",
    frequency: "weekly",
    timeOfDay: "11:00",
    lastRun: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    nextRun: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
    status: "active",
    agentId: "agent-1"
  },
  {
    id: "workflow-6",
    name: "Cross-Platform Echo Scan",
    description: "Tracks content performance across multiple platforms",
    frequency: "daily",
    timeOfDay: "16:00",
    lastRun: new Date(Date.now() - 8 * 60 * 60 * 1000),
    nextRun: new Date(Date.now() + 16 * 60 * 60 * 1000),
    status: "paused",
    agentId: "agent-1"
  },
  {
    id: "workflow-7",
    name: "Seasonality Forecaster",
    description: "Predicts content performance based on seasonal trends",
    frequency: "monthly",
    timeOfDay: "09:30",
    lastRun: new Date(Date.now() - 25 * 24 * 60 * 60 * 1000),
    nextRun: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
    status: "active",
    agentId: "agent-1"
  },
  {
    id: "workflow-8",
    name: "Thumbnail DNA Decomposer",
    description: "Analyzes successful thumbnail patterns and elements",
    frequency: "weekly",
    timeOfDay: "13:00",
    lastRun: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
    nextRun: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
    status: "error",
    agentId: "agent-1"
  },
  {
    id: "workflow-9",
    name: "Multilingual White-Space Finder",
    description: "Identifies untapped content opportunities in different languages",
    frequency: "monthly",
    timeOfDay: "10:30",
    lastRun: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000),
    nextRun: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
    status: "active",
    agentId: "agent-1"
  }
];
