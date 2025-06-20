# Niche Scout Workflow

**Last Updated:** 2025-05-10
**Owner:** Social Intelligence Team
**Status:** Active

## Overview

The Niche Scout workflow is a specialized analysis tool designed to identify high-potential, fast-growing, and Shorts-friendly YouTube niches. It allows users to research YouTube market opportunities by selecting categories, subcategories, and configuring data sources for comprehensive trend analysis.

This workflow leverages the Social Intelligence Agent's capabilities to analyze YouTube data, identify trending topics, and calculate opportunity scores across various content niches. The results help content creators and marketers identify underserved areas with high growth potential and lower competition.

## Workflow Metadata

| Attribute | Value |
|-----------|-------|
| Primary Agent | [Social Intelligence Agent](../../agents/architect-apiligence-agent.md) |
| Supporting Agents | None |
| Projects | YouTube Content Strategy, Market Research |
| Category | Analysis |
| Trigger Type | Manual |
| Average Runtime | 2-3 minutes |

## Workflow Diagram

```
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│                   │     │                   │     │                   │
│  Step 1:          │     │  Step 2:          │     │  Step 3:          │
│  Category         │────►│  Budget &         │────►│  Confirm &        │
│  Selection        │     │  Data Sources     │     │  Run Analysis     │
│                   │     │                   │     │                   │
└───────────────────┘     └───────────────────┘     └───────────────────┘
          │                        │                        │
          ▼                        ▼                        ▼
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│ - Main Category   │     │ - Budget Setting  │     │ - Review Settings │
│ - Subcategory     │     │ - Data Sources    │     │ - Estimated Time  │
│                   │     │ - Accuracy Level  │     │ - Estimated Cost  │
└───────────────────┘     └───────────────────┘     └───────────────────┘
                                                             │
                                                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│                          API Processing                                 │
│                                                                         │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐                │
│  │ Fetch Data  │────►│ Analyze     │────►│ Generate    │                │
│  │ from Sources│     │ Trends      │     │ Results     │                │
│  └─────────────┘     └─────────────┘     └─────────────┘                │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        ┌─────────────────────────┐
                        │                         │
                        │  Results Visualization  │
                        │                         │
                        └─────────────────────────┘
```

## Input Parameters

| Parameter | Type | Description | Required | Default |
|-----------|------|-------------|----------|---------|
| category | string | Main content category | Yes | - |
| subcategory | string | Specific content subcategory | Yes | - |
| budget | number | Maximum budget for API calls and processing | No | 100 |
| dataSources | object | Configuration of data sources to use | No | All sources enabled |

## Output

The Niche Scout workflow provides a comprehensive analysis of trending YouTube niches, opportunity scores, and recommendations.

**Example Output:**
```json
{
  "run_date": "2025-05-10T15:22:43Z",
  "trending_niches": [
    {
      "query": "nursery rhymes for toddlers",
      "view_sum": 12500000,
      "rsv": 0.95,
      "view_rank": 1,
      "rsv_rank": 1,
      "score": 0.89,
      "x": 10,
      "y": 85,
      "niche": 3
    },
    {
      "query": "alphabet songs for kids",
      "view_sum": 9800000,
      "rsv": 0.92,
      "view_rank": 2,
      "rsv_rank": 2,
      "score": 0.86,
      "x": 20,
      "y": 70,
      "niche": 3
    }
    // Additional trending niches...
  ],
  "top_niches": [
    // Top 5 most promising niches
  ],
  "visualization_url": "https://example.com/visualization",
  "actual_cost": 95.50,
  "actual_processing_time": 120.5,
  "status": "completed"
}
```

## Workflow Steps

### 1. Category Selection

**Description:** The user selects a main content category and subcategory for analysis.

**Component/Agent:** NicheScoutWizard (Frontend)

**Actions:**
- Display available main categories
- Update subcategory options based on main category selection
- Validate selection before proceeding to next step

**Output:** Selected category and subcategory

### 2. Budget and Data Source Configuration

**Description:** The user configures budget constraints and data sources for the analysis.

**Component/Agent:** NicheScoutWizard (Frontend)

**Actions:**
- Allow budget setting for API calls and processing
- Configure which data sources to use (YouTube API, trending data, etc.)
- Select desired accuracy level for results

**Output:** Configured budget and data sources settings

### 3. Analysis Confirmation and Execution

**Description:** The user reviews settings, views estimated cost and time, and initiates the analysis.

**Component/Agent:** NicheScoutWizard (Frontend)

**Actions:**
- Display summary of selected parameters
- Show estimated processing time and cost
- Trigger analysis execution upon confirmation

**Output:** Analysis request submitted

### 4. Data Processing

**Description:** The backend service processes the request, fetches data, and generates results.

**Component/Agent:** Social Intelligence Agent (Backend)

**Actions:**
- Retrieve trend data from various sources based on configuration
- Apply analysis algorithms to identify opportunities
- Calculate growth rates and opportunity scores
- Generate comprehensive results

**Output:** Complete niche analysis results

### 5. Results Presentation

**Description:** The results are formatted and presented to the user.

**Component/Agent:** Frontend UI

**Actions:**
- Display trending niches with scores
- Show visualizations of opportunity landscape
- Provide actionable recommendations

**Output:** Visual and textual presentation of niche opportunities

## Error Handling

### Common Errors

| Error | Cause | Handling Strategy |
|-------|-------|-------------------|
| API Unavailability | YouTube API rate limits or service outage | Fall back to cached data or simulated results |
| Insufficient Data | Too narrow category or limited historical data | Broaden search parameters or add simulated data |
| Budget Exceeded | API costs exceed specified budget | Limit results and provide partial analysis |
| Processing Timeout | Analysis takes too long to complete | Return partial results with notification |
| Invalid Category | User selects unsupported category | Display friendly error and suggest alternatives |

### Recovery Mechanisms

1. **Graceful Degradation:**
   - If the backend service is unavailable, the system falls back to cached data or simulated results
   - If YouTube API limits are reached, the workflow uses database-stored trends
   - If a specific data source fails, others continue processing

2. **Error Notifications:**
   - Users receive clear error messages explaining the issue
   - Suggestions for resolution are provided when possible

3. **Auto-retry Logic:**
   - Transient failures are automatically retried with exponential backoff
   - Service health is continuously monitored for availability

## Performance Considerations

- **Average Runtime:** 2-3 minutes for comprehensive analysis
- **Resource Requirements:**
  - Frontend: Minimal (React component rendering)
  - Backend: Moderate (API processing, data analysis)
- **Scalability Notes:**
  - Horizontal scaling for the Social Intelligence service
  - Rate limiting to prevent API exhaustion
  - Redis caching for frequently requested categories
- **Optimization Tips:**
  - Use cached results for recently analyzed categories
  - Consider scheduled analysis for high-traffic niches
  - Adjust accuracy level to balance speed vs. depth

## Example Use Cases

### Use Case 1: Kids Educational Content Research

**Scenario:** A content creator wants to explore trending opportunities in children's educational content.

**Example Input:**
```json
{
  "category": "kids",
  "subcategory": "kids.nursery",
  "budget": 150,
  "dataSources": {
    "youtubeAPI": true,
    "trendingData": true,
    "historicalStats": true,
    "competitorAnalysis": true
  }
}
```

**Expected Output:**
```json
{
  "run_date": "2025-05-10T14:30:22Z",
  "trending_niches": [
    {
      "query": "classic nursery rhymes",
      "view_sum": 15000000,
      "rsv": 0.97,
      "score": 0.93,
      "niche": 1
    },
    {
      "query": "lullabies for babies",
      "view_sum": 12500000,
      "rsv": 0.94,
      "score": 0.91,
      "niche": 1
    },
    {
      "query": "abc songs for toddlers",
      "view_sum": 9800000,
      "rsv": 0.90,
      "score": 0.88,
      "niche": 2
    }
  ],
  "top_niches": [
    {
      "query": "classic nursery rhymes",
      "view_sum": 15000000,
      "rsv": 0.97,
      "score": 0.93,
      "niche": 1
    }
  ],
  "recommendations": [
    "Focus on classic nursery rhymes with modern animation",
    "Create content under 60 seconds for optimal Shorts performance",
    "Target educational content with alphabet and counting themes"
  ],
  "actual_cost": 142.75,
  "actual_processing_time": 145.2
}
```

### Use Case 2: Tech Review Opportunity Analysis

**Scenario:** A tech reviewer wants to identify underserved niches in technology product reviews.

**Example Input:**
```json
{
  "category": "tech",
  "subcategory": "tech.gadgets",
  "budget": 100,
  "dataSources": {
    "youtubeAPI": true,
    "trendingData": true,
    "historicalStats": false,
    "competitorAnalysis": true
  }
}
```

**Expected Output:**
```json
{
  "run_date": "2025-05-10T16:45:12Z",
  "trending_niches": [
    {
      "query": "budget wireless earbuds",
      "view_sum": 8200000,
      "rsv": 0.88,
      "score": 0.85,
      "niche": 1
    },
    {
      "query": "smartphone camera comparison",
      "view_sum": 7500000,
      "rsv": 0.86,
      "score": 0.83,
      "niche": 1
    },
    {
      "query": "smart home gadgets under $50",
      "view_sum": 6800000,
      "rsv": 0.82,
      "score": 0.79,
      "niche": 2
    }
  ],
  "top_niches": [
    {
      "query": "budget wireless earbuds",
      "view_sum": 8200000,
      "rsv": 0.88,
      "score": 0.85,
      "niche": 1
    }
  ],
  "recommendations": [
    "Focus on budget-friendly alternatives to popular tech products",
    "Create side-by-side comparison videos optimized for Shorts",
    "Target value-focused tech niches with moderate competition"
  ],
  "actual_cost": 95.50,
  "actual_processing_time": 128.3
}
```

## Implementation Notes

### Technical Details

The Niche Scout workflow combines frontend and backend components:

1. **Frontend Implementation:**
   - React-based wizard component with step-by-step user interface
   - State management via React hooks (useNicheScoutWizard)
   - API communication through service layer (youtube-service.ts)
   - Graceful degradation with mock data when APIs are unavailable

2. **Backend Implementation:**
   - Python-based service in the Social Intelligence Agent
   - Multiple data source adapters for YouTube API and other sources
   - Cached database of previously analyzed niches
   - Prometheus metrics for performance monitoring
   - Fallback mechanisms for handling API limitations

3. **API Endpoints:**
   - `/api/youtube/niche-scout`: Main endpoint for analysis requests
   - `/api/workflow/history`: Endpoint for retrieving past workflow runs
   - `/api/workflow/result/{id}`: Endpoint for accessing specific workflow results

### Deployment Considerations

1. **Environment Variables:**
   - `YOUTUBE_API_KEY`: Required for YouTube API access
   - `GCP_PROJECT_ID`: Google Cloud project ID
   - `OPENAI_API_KEY`: Required for AI processing of trends

2. **Service Dependencies:**
   - Requires the Social Intelligence service to be running
   - Requires Redis for caching and state management
   - Requires database access for state persistence

3. **Integration Points:**
   - Integrates with Mission Control UI for workflow triggering
   - Can be scheduled for recurring analysis

## Current Limitations

- Analysis limited to YouTube platform (no cross-platform analysis)
- Limited historical data availability (up to 1 year back)
- Maximum of 100 trending niches per analysis
- Results accuracy dependent on data freshness and API availability
- Budget constraints may limit analysis depth
- Processing time increases with analysis scope

## Future Enhancements

- Cross-platform analysis (YouTube, TikTok, Instagram)
- Advanced competitive analysis features
- Content strategy recommendations based on niche analysis
- Integration with content planning tools
- Automated trend alerting for monitored niches
- Custom category definitions for specialized industries
- AI-generated content ideas for identified niches

## Related Workflows

- [Seed to Blueprint Workflow](../by-project/content-creation/seed-to-blueprint-workflow.md)
- [Content Performance Analysis](../by-agent/architect-apiligence/content-performance-analysis.md)
- [Audience Insights Workflow](../by-agent/architect-apiligence/audience-insights-workflow.md)

## References

- [YouTube API Documentation](https://developers.google.com/youtube/v3)
- [Social Intelligence Agent Documentation](../../agents/architect-apiligence-agent.md)
- [Niche Scout Implementation Guide](./niche-scout-implementation-guide.md)
