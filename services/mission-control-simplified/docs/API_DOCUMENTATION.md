# Niche-Scout API Documentation

## Current API (Social Intelligence Agent)

### Base URL
```
http://[SOCIAL_INTEL_HOST]:[SOCIAL_INTEL_PORT]
```

### Endpoints

#### Check Status
```
GET /status
```

Response:
```json
{
  "agent": "social-intel",
  "version": "1.0.0",
  "status": "running",
  "supported_intents": [
    "TREND_ANALYSIS",
    "SOCIAL_MONITOR",
    "SENTIMENT_ANALYSIS"
  ]
}
```

#### Niche Scout
```
POST /api/youtube/niche-scout
```

Request body:
```json
{
  "query": "mobile",
  "category": "Gaming",
  "subcategories": ["Mobile Gaming"],
  "timeRange": "Last 30 days",
  "demographics": "All"
}
```

Response:
```json
{
  "date": "2025-05-08",
  "query": null,
  "category": null,
  "subcategory": null,
  "niches": [
    {
      "name": "Financial Literacy Shorts",
      "growth_rate": 87.5,
      "shorts_friendly": true,
      "competition_level": "Medium",
      "viewer_demographics": {
        "age_groups": ["18-24", "25-34"],
        "gender_split": {"male": 65, "female": 35}
      },
      "trending_topics": [
        "Stock market tips",
        "Passive income ideas",
        "Investing for beginners"
      ],
      "top_channels": [
        {"name": "FinanceQuick", "subs": 2800000},
        {"name": "MoneyMinute", "subs": 1400000}
      ]
    },
    // Additional niches...
  ],
  "analysis_summary": {
    "fastest_growing": "Financial Literacy Shorts",
    "most_shorts_friendly": "Financial Literacy Shorts",
    "lowest_competition": "Financial Literacy Shorts"
  },
  "recommendations": [
    "Focus on Financial Literacy Shorts for highest growth potential",
    "Create content under 60 seconds for optimal Shorts performance",
    "Target trending topics with high search volume but moderate competition"
  ]
}
```

### Notes
- The API currently ignores the request parameters
- All responses return the same niches regardless of query/category
- Our client-side transformation converts these to relevant niches

## Current Workaround (Client-side Transform)

### Integration Layer
The integration layer in `integrate-with-social-intel.js` transforms the Social Intelligence API response to make it relevant to the user's search query and category.

### Transformation Logic
1. Detect when the API returns `query: null` and `category: null`
2. Replace niche names with relevant ones based on search parameters
3. Update trending topics to match the new niches
4. Preserve original metrics (growth rates, competition levels)
5. Return the transformed response to the UI

### Example Transformed Response
```json
{
  "date": "2025-05-08",
  "query": "mobile",
  "category": "Gaming",
  "subcategory": "Mobile Gaming",
  "niches": [
    {
      "name": "Mobile Gaming",
      "growth_rate": 87.5,
      "shorts_friendly": true,
      "competition_level": "Medium",
      "viewer_demographics": {
        "age_groups": ["18-24", "25-34"],
        "gender_split": {"male": 65, "female": 35}
      },
      "trending_topics": [
        "Game development tutorials",
        "Mobile gaming optimization",
        "Indie game showcases"
      ],
      "top_channels": [
        {"name": "FinanceQuick", "subs": 2800000},
        {"name": "MoneyMinute", "subs": 1400000}
      ]
    },
    // Additional transformed niches...
  ],
  "analysis_summary": {
    "fastest_growing": "Mobile Gaming",
    "most_shorts_friendly": "Mobile Gaming",
    "lowest_competition": "Mobile Gaming"
  },
  "recommendations": [
    "Focus on Mobile Gaming for highest growth potential",
    "Create gaming content with clear tutorials and tips",
    "Target trending topics like Game development tutorials"
  ],
  "_filtered": true,
  "_originalApiData": {
    // Original API response stored for debugging
  }
}
```

## Proxy Service API (Future)

### Base URL
```
http://proxy-api.example.com
```

### Endpoints

#### Niche Scout (Transformed)
```
POST /workflows/niche-scout
```

Request body:
```json
{
  "query": "mobile",
  "category": "Gaming",
  "subcategories": ["Mobile Gaming"],
  "timeRange": "Last 30 days",
  "demographics": "All"
}
```

Response:
```json
{
  "date": "2025-05-08",
  "query": "mobile",
  "category": "Gaming",
  "subcategory": "Mobile Gaming",
  "niches": [
    {
      "name": "Mobile Gaming",
      "growth_rate": 87.5,
      "shorts_friendly": true,
      "competition_level": "Medium",
      "viewer_demographics": {
        "age_groups": ["18-24", "25-34"],
        "gender_split": {"male": 65, "female": 35}
      },
      "trending_topics": [
        "Game development tutorials",
        "Mobile gaming optimization",
        "Indie game showcases"
      ],
      "top_channels": [
        {"name": "MobileGamerPro", "subs": 2800000},
        {"name": "GameHubMobile", "subs": 1400000}
      ]
    },
    // Additional relevant niches...
  ],
  "analysis_summary": {
    "fastest_growing": "Mobile Gaming",
    "most_shorts_friendly": "Mobile Gaming",
    "lowest_competition": "Mobile Gaming"
  },
  "recommendations": [
    "Focus on Mobile Gaming for highest growth potential",
    "Create gaming content with clear tutorials and tips",
    "Target trending topics like Game development tutorials"
  ]
}
```

#### Cache Management (Admin Only)
```
DELETE /cache/:key
```

Headers:
```
Authorization: Bearer <admin-token>
```

Response:
```json
{
  "success": true,
  "message": "Cache entry deleted"
}
```

#### Health Check
```
GET /health
```

Response:
```json
{
  "status": "healthy",
  "uptime": 1234.56,
  "version": "1.0.0",
  "dependencies": {
    "redis": "connected",
    "social_intel": "connected"
  }
}
```

#### Metrics
```
GET /metrics
```

Response: Prometheus-formatted metrics
```
# HELP proxy_api_calls_total Total requests made to the Social Intelligence API
# TYPE proxy_api_calls_total counter
proxy_api_calls_total{endpoint="niche-scout"} 1234

# HELP proxy_cache_hit_total Total cache hits
# TYPE proxy_cache_hit_total counter
proxy_cache_hit_total{endpoint="niche-scout"} 987

# [additional metrics...]
```

## Social Intelligence API v2 (Target - Phase 2)

### Base URL
```
http://[SOCIAL_INTEL_HOST]:[SOCIAL_INTEL_PORT]
```

### Endpoints

#### Niche Scout v2
```
POST /api/v2/niche-scout
```

Request body:
```json
{
  "query": "mobile",
  "category": "Gaming",
  "subcategories": ["Mobile Gaming"],
  "timeRange": "Last 30 days",
  "demographics": "All"
}
```

Response:
```json
{
  "date": "2025-05-08",
  "query": "mobile",
  "category": "Gaming",
  "subcategory": "Mobile Gaming",
  "niches": [
    {
      "name": "Mobile Gaming",
      "growth_rate": 87.5,
      "shorts_friendly": true,
      "competition_level": "Medium",
      "viewer_demographics": {
        "age_groups": ["18-24", "25-34"],
        "gender_split": {"male": 65, "female": 35}
      },
      "trending_topics": [
        "Game development tutorials",
        "Mobile gaming optimization",
        "Indie game showcases"
      ],
      "top_channels": [
        {"name": "MobileGamerPro", "subs": 2800000},
        {"name": "GameHubMobile", "subs": 1400000}
      ],
      "opportunity_score": {
        "total": 78,
        "demand": 0.85,
        "monetization": 0.72,
        "supply": 0.65
      }
    },
    // Additional niches...
  ],
  "analysis_summary": {
    "fastest_growing": "Mobile Gaming",
    "most_shorts_friendly": "Mobile Gaming",
    "lowest_competition": "Mobile Gaming"
  },
  "recommendations": [
    "Focus on Mobile Gaming for highest growth potential",
    "Create gaming content with clear tutorials and tips",
    "Target trending topics like Game development tutorials"
  ],
  "meta": {
    "version": "2.0.0",
    "processing_time_ms": 1234,
    "filters_applied": true,
    "match_count": 12,
    "filtered_count": 8
  }
}
```

### Key Differences in v2 API
1. Parameter handling: Properly filters based on query and category
2. Opportunity score breakdown: Exposes demand, monetization, and supply components
3. Channel names: Contextually relevant to the niche
4. Meta information: Includes processing stats and version info
5. Explicit path versioning: `/api/v2/` prefix
