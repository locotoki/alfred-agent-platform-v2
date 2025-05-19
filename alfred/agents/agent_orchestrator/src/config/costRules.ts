
export const COST_PER_SOURCE = {
  youtube: 0.24,
  reddit: 0.16,
  amazon: 0.10,
  sentiment: 0.50,
};

export const COST_TOOLTIP = {
  youtube: "channel metadata + captions",
  reddit: "top 1k posts including comments",
  amazon: "keyword API (up to 3k items)",
  sentiment: "OpenAI -text-embedding-3 small",
};

export const ETA_BASE_SEC = 75;           // fixed overhead
export const ETA_PER_1K_SEC = 60;         // per-1000-items
export const BUDGET_MIN = 50;
export const BUDGET_MAX = 500;
