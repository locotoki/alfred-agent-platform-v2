# API Changelog - Phase 2 (Advanced Analytics)

This document outlines all API changes and additions for Phase 2 of the Social Intelligence service.

## New Endpoints

### Trend Analytics

#### `GET /trend-chart`
Returns time-series data for visualizing trend patterns.

**Parameters:**
- `niche_id` (required): ID of the niche to analyze
- `timeframe`: Time period to analyze (default: "90d", options: "30d", "90d", "1y", "all")
- `metrics`: Comma-separated list of metrics to include (default: "demand,supply,opportunity")
- `interval`: Data point interval (default: "day", options: "day", "week", "month")
- `forecast`: Whether to include forecasted data points (default: false)
- `forecast_days`: Number of days to forecast (default: 30, max: 90)

**Response Schema:**
```json
{
  "niche_id": 123,
  "niche_phrase": "gaming tutorials",
  "timeframe": "90d",
  "interval": "day",
  "series": [
    {
      "metric": "demand_score",
      "label": "Audience Demand",
      "color": "#3498DB",
      "data": [
        {"date": "2025-02-01", "value": 0.82, "type": "historical"},
        {"date": "2025-02-02", "value": 0.83, "type": "historical"},
        // ...more data points
        {"date": "2025-05-01", "value": 0.87, "type": "forecast", "confidence": 0.92}
      ]
    },
    // Additional series for other metrics
  ]
}
```

#### `GET /trend-correlations`
Identifies correlations between different niches or metrics.

**Parameters:**
- `niche_id` (required): Primary niche ID
- `comparison_niche_ids`: Comma-separated list of niche IDs to compare
- `metric`: Metric to compare (default: "demand_score")
- `timeframe`: Time period to analyze (default: "90d")

**Response Schema:**
```json
{
  "primary_niche": {
    "id": 123,
    "phrase": "gaming tutorials"
  },
  "correlations": [
    {
      "niche": {
        "id": 456,
        "phrase": "game reviews"
      },
      "correlation_coefficient": 0.87,
      "relationship": "strong_positive",
      "lag_days": 7,
      "insights": "Demand for game reviews typically precedes demand for gaming tutorials by 7 days"
    },
    // Additional correlations
  ]
}
```

### Competitive Intelligence

#### `GET /competitor-heatmap`
Returns competitor density and performance across sub-topics.

**Parameters:**
- `niche_id` (required): ID of the niche to analyze
- `dimensions`: Number of dimensions to include (default: 10, max: 20)
- `metric`: Metric to visualize (default: "content_volume", options: "content_volume", "engagement", "growth")

**Response Schema:**
```json
{
  "niche_id": 123,
  "niche_phrase": "gaming tutorials",
  "dimensions": 10,
  "metric": "content_volume",
  "heatmap_data": {
    "x_axis": {
      "label": "Content Type",
      "values": ["Beginner", "Intermediate", "Advanced", "Speedrun", "Mods", "Walkthrough", "Tips", "Strategy", "Review", "Reaction"]
    },
    "y_axis": {
      "label": "Game Genre",
      "values": ["FPS", "RPG", "Strategy", "Simulation", "Sports", "Puzzle", "Adventure", "Action", "Horror", "MMO"]
    },
    "values": [
      [0.8, 0.7, 0.4, 0.9, 0.3, 0.5, 0.8, 0.6, 0.2, 0.1],
      [0.6, 0.5, 0.3, 0.4, 0.2, 0.5, 0.7, 0.3, 0.5, 0.2],
      // ...more rows
    ],
    "opportunities": [
      {"x": 2, "y": 4, "value": 0.2, "opportunity_score": 0.92, "description": "Advanced tutorials for simulation games"}
      // ...more opportunities
    ]
  }
}
```

#### `GET /gap-analysis`
Identifies content gaps in the competitive landscape.

**Parameters:**
- `niche_id` (required): ID of the niche to analyze
- `min_opportunity`: Minimum opportunity score to include (default: 0.7)
- `limit`: Maximum number of gaps to return (default: 10)

**Response Schema:**
```json
{
  "niche_id": 123,
  "niche_phrase": "gaming tutorials",
  "gaps": [
    {
      "sub_niche": "Advanced Unity Engine Tutorials",
      "demand_score": 0.86,
      "supply_score": 0.23,
      "opportunity_score": 0.94,
      "estimated_audience": 450000,
      "content_recommendation": "In-depth tutorials on advanced Unity features like custom shaders and networking",
      "competitor_count": 3,
      "top_competitor": "GameDevHQ"
    },
    // Additional gaps
  ]
}
```

### Cross-Platform Insights

#### `GET /cross-platform-analysis`
Compares metrics across different platforms for a given niche.

**Parameters:**
- `niche_id` (required): ID of the niche to analyze
- `platforms`: Comma-separated list of platforms (default: "youtube,tiktok,instagram")
- `metrics`: Comma-separated list of metrics (default: "demand,supply,engagement,growth")

**Response Schema:**
```json
{
  "niche_id": 123,
  "niche_phrase": "gaming tutorials",
  "cross_platform_data": {
    "youtube": {
      "demand_score": 0.82,
      "supply_score": 0.65,
      "engagement_score": 0.72,
      "growth_rate": 0.12,
      "audience_demographics": {
        "age_groups": {"18-24": 0.35, "25-34": 0.42, "35-44": 0.15, "45+": 0.08},
        "gender_split": {"male": 0.76, "female": 0.24}
      }
    },
    "tiktok": {
      // Similar structure
    },
    "instagram": {
      // Similar structure
    }
  },
  "insights": [
    {
      "type": "platform_opportunity",
      "description": "TikTok shows high demand (0.85) with low supply (0.32), representing an immediate opportunity",
      "score": 0.91
    },
    // Additional insights
  ]
}
```

### Personalized Recommendations

#### `GET /content-recommendations`
Provides personalized content recommendations based on user history and niche.

**Parameters:**
- `niche_id` (required): ID of the niche for recommendations
- `user_id`: User ID for personalization (if omitted, provides general recommendations)
- `count`: Number of recommendations to return (default: 5)
- `content_type`: Type of content to recommend (default: "video", options: "video", "short", "stream", "post")

**Response Schema:**
```json
{
  "niche_id": 123,
  "niche_phrase": "gaming tutorials",
  "personalized_for": "user-456",
  "content_recommendations": [
    {
      "title": "Advanced Unity Lighting Tutorials",
      "description": "Create a 3-part series covering dynamic lighting, global illumination, and shader-based lighting effects",
      "opportunity_score": 0.89,
      "estimated_views": 250000,
      "audience_match": 0.92,
      "content_format": {
        "type": "video_series",
        "recommended_length": "15-20 minutes",
        "episode_count": 3
      },
      "keywords": ["unity3d", "game lighting", "global illumination", "shader lighting"],
      "trend_status": "rising",
      "competition_level": "low"
    },
    // Additional recommendations
  ]
}
```

## Modified Endpoints

### Enhancements to Existing Endpoints

#### `GET /niche-scout`
**Added Parameters:**
- `include_analytics`: Whether to include analytics data (default: false)
- `analytics_depth`: Detail level for analytics (default: "summary", options: "summary", "detailed")

**Added Response Fields:**
```json
{
  // Existing fields remain the same
  "analytics": {
    "trend_direction": "rising",
    "trend_stability": 0.82,
    "seasonal_pattern": "consistent",
    "platform_distribution": {
      "youtube": 0.68,
      "tiktok": 0.24,
      "instagram": 0.08
    },
    "search_volume_trend": [
      {"period": "2025-Q1", "value": 150000},
      {"period": "2025-Q2", "value": 175000}
    ]
  }
}
```

#### `GET /hot-niches`
**Added Parameters:**
- `trend_filter`: Filter by trend direction (options: "rising", "stable", "falling")
- `days_rising`: Minimum consecutive days of rising trend (default: 7)
- `min_trend_slope`: Minimum trend slope to qualify as rising (default: 0.05)

**Added Response Fields:**
```json
{
  // Existing structure remains
  "niches": [
    {
      // Existing fields remain
      "trend_metrics": {
        "direction": "rising",
        "days_rising": 12,
        "slope": 0.08,
        "volatility": 0.12
      }
    }
  ]
}
```

## Deprecation Notices

### Parameters Marked for Deprecation

The following parameters will be deprecated in favor of new analytics-focused parameters:

- `simple_score` on `/niche-scout` - Use `include_analytics=true` instead
- `basic_view` on `/seed-to-blueprint` - Use analytics-enriched view instead

### Planned Removal Timeline

- Phase 2 Release: Deprecation warnings in responses
- Phase 2 + 30 days: Parameters continue to work but return warnings
- Phase 2 + 90 days: Parameters removed, requests using them will receive error 400

## API Version Information

- Current Version: `v2.0.0`
- Previous Version: `v1.0.0`
- Release Date: Scheduled for 2025-06-15

## Backward Compatibility

All existing endpoints will maintain backward compatibility. The changes are additive with optional parameters, ensuring existing integrations continue to work.