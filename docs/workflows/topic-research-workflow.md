# Topic Research Workflow

**Last Updated:** 2025-05-12  
**Owner:** Content Factory Team  
**Status:** Active

## Overview

The Topic Research Workflow is a comprehensive system for analyzing, evaluating, and prioritizing content topics based on data-driven insights. This workflow leverages multiple data sources to identify high-potential topics, assess competition, and develop content strategies that maximize engagement and growth opportunities. The workflow serves as a foundation for content planning across channels and platforms.

## Workflow Metadata

| Attribute | Value |
|-----------|-------|
| Primary Agent | [Social Intelligence Research Agent](../../agents/social-intel/agent.md) |
| Supporting Agents | Content Strategy Agent |
| Projects | Content Factory, Niche Scout |
| Category | Research & Analysis |
| Trigger Type | Manual/Scheduled |
| Average Runtime | 30-45 minutes |

## Workflow Diagram

```
┌─────────────────┐     ┌──────────────────┐     ┌────────────────┐
│ Topic           │     │ Semantic         │     │ Competitive    │
│ Harvesting      │────▶│ Analysis         │────▶│ Landscape      │
│                 │     │                  │     │ Mapping        │
└─────────────────┘     └──────────────────┘     └────────────────┘
                                                         │
┌─────────────────┐     ┌──────────────────┐            ▼
│ Opportunity     │     │ Gap              │     ┌────────────────┐
│ Scoring         │◀────│ Analysis         │◀────│ Topic          │
│                 │     │                  │     │ Clustering     │
└─────────────────┘     └──────────────────┘     └────────────────┘
        │
        ▼
┌─────────────────┐
│ Topic Strategy  │
│ Generation      │
└─────────────────┘
```

## Input Parameters

| Parameter | Type | Description | Required | Default |
|-----------|------|-------------|----------|---------|
| base_topics | array | Initial topics to research | Yes | - |
| competitor_channels | array | Channels to include in analysis | No | [] |
| platform | string | Primary platform for analysis (youtube, tiktok, etc.) | No | "youtube" |
| expansion_factor | integer | How many related topics to find per seed topic | No | 5 |
| min_score_threshold | float | Minimum opportunity score (0-10) | No | 3.0 |

## Output

The workflow produces a comprehensive topic research report with prioritized topics, competitive analysis, and content strategy recommendations.

**Example Output:**
```json
{
  "report_id": "TR_20250512_123456",
  "base_topics": ["AI programming", "machine learning tutorials"],
  "date_generated": "2025-05-12T14:15:30Z",
  "topic_clusters": [
    {
      "cluster_name": "Machine Learning Fundamentals",
      "topics": [
        {
          "topic": "neural networks basics",
          "search_volume": 12500,
          "competition_score": 7.2,
          "opportunity_score": 6.8,
          "trending_direction": "stable"
        },
        {
          "topic": "supervised learning tutorials",
          "search_volume": 8700,
          "competition_score": 6.5,
          "opportunity_score": 7.3,
          "trending_direction": "increasing"
        }
      ],
      "cluster_opportunity_score": 7.1,
      "recommended_content_formats": ["tutorial series", "interactive demos"]
    }
  ],
  "top_opportunities": [
    {
      "topic": "machine learning for beginners",
      "search_volume": 22000,
      "competition_score": 8.5,
      "opportunity_score": 9.2,
      "trending_direction": "increasing",
      "gap_analysis": {
        "content_gaps": ["practical applications", "code implementation"],
        "competitor_coverage": 65,
        "differentiation_strategy": "Focus on real-world applications with step-by-step implementation"
      }
    }
  ],
  "competitive_landscape": {
    "top_competitors": [
      {
        "channel_name": "TechWithTim",
        "subscriber_count": 980000,
        "topic_coverage": ["python basics", "machine learning tutorials"],
        "content_approach": "Project-based learning with code explanations"
      }
    ]
  },
  "strategic_recommendations": [
    {
      "recommendation": "Develop a 10-part series on ML fundamentals with real-world applications",
      "reasoning": "High search volume with identifiable content gaps in practical implementation",
      "expected_performance": "High",
      "audience_match": "Beginner to intermediate programmers"
    }
  ]
}
```

## Workflow Steps

### 1. Topic Harvesting

**Description:** Collects potential topics from multiple data sources

**Component/Agent:** Social Intelligence Research Agent

**Actions:**
- Expand seed topics using YouTube API suggestions
- Extract related topics from top videos in the niche
- Collect trending topics from Google Trends API
- Gather keywords from competitor video metadata
- Query search volume data for potential topics

**Output:** Comprehensive list of potential topics with initial metadata

### 2. Semantic Analysis

**Description:** Analyzes topic relationships and semantic structures

**Component/Agent:** Social Intelligence Research Agent

**Actions:**
- Generate embeddings for all harvested topics
- Calculate semantic similarity between topics
- Identify parent-child relationships between topics
- Extract entities and concepts from topics
- Create semantic network visualization

**Output:** Enriched topic dataset with semantic relationships

### 3. Competitive Landscape Mapping

**Description:** Maps the competitive environment for each topic

**Component/Agent:** Social Intelligence Research Agent

**Actions:**
- Identify top creators for each topic
- Analyze content approach and format for each competitor
- Measure engagement metrics across competitive content
- Evaluate production quality and approach
- Create competitor positioning map

**Output:** Competitive landscape data for each topic

### 4. Topic Clustering

**Description:** Groups related topics into meaningful clusters

**Component/Agent:** Social Intelligence Research Agent

**Actions:**
- Apply UMAP dimensionality reduction to topic embeddings
- Perform K-means clustering on reduced embeddings
- Generate descriptive names for each cluster
- Calculate cluster coherence scores
- Identify central topics within each cluster

**Output:** Organized topic clusters with metadata

### 5. Gap Analysis

**Description:** Identifies content gaps and opportunities

**Component/Agent:** Content Strategy Agent

**Actions:**
- Compare topic coverage across competitor channels
- Identify underserved topics with high search interest
- Analyze audience questions not addressed by competitors
- Evaluate content quality gaps in existing material
- Calculate content saturation scores

**Output:** Gap analysis report with opportunity areas

### 6. Opportunity Scoring

**Description:** Scores and ranks topics by opportunity potential

**Component/Agent:** Content Strategy Agent

**Actions:**
- Calculate composite opportunity score from multiple factors
- Balance search volume against competition
- Apply trending direction weighting
- Consider content format differentiation potential
- Generate ranked opportunity list

**Output:** Scored and ranked topic opportunities

### 7. Topic Strategy Generation

**Description:** Develops strategic recommendations for content creation

**Component/Agent:** Content Strategy Agent

**Actions:**
- Generate content strategy for top opportunity topics
- Recommend optimal content formats and approaches
- Create content differentiation strategies
- Develop audience targeting recommendations
- Outline potential content series and structure

**Output:** Strategic content recommendations for prioritized topics

## Error Handling

### Common Errors

| Error | Cause | Handling Strategy |
|-------|-------|-------------------|
| API Rate Limiting | Exceeding YouTube/Google API quotas | Implement exponential backoff and request batching |
| Insufficient Topic Data | New or niche topics with limited signals | Expand search to related topics and use alternative data sources |
| Clustering Failure | Too few topics or high dimensionality | Adjust dimensionality parameters and clustering approach |
| Search Volume Unavailability | API restrictions or new topics | Fall back to relative volume estimates from video metrics |
| Competitor Analysis Failure | Private analytics or blocked channels | Use available public data and estimate from engagement metrics |

### Recovery Mechanisms

The workflow implements several recovery mechanisms to ensure resilience:

- Modular processing with independent checkpoint storage
- Alternative data source fallbacks for critical information
- Progressive narrowing of scope when full analysis fails
- Graceful degradation with partial results when complete analysis is unavailable
- Results caching to reduce API dependencies on subsequent runs

## Performance Considerations

- **Average Runtime:** 30-45 minutes for standard analysis
- **Resource Requirements:** 
  - 4GB RAM minimum
  - 2 CPU cores recommended
  - ~200MB temporary storage for data processing
- **Scalability Notes:** 
  - Runtime scales approximately linearly with expansion_factor
  - API rate limits are the primary bottleneck for large-scale analysis
- **Optimization Tips:** 
  - Pre-filter competitors to most relevant channels
  - Cache embedding calculations for repeated topic analysis
  - Use batched API requests where possible

## Example Use Cases

### Use Case 1: New Channel Content Strategy

**Scenario:** Developing a content strategy for a new educational technology channel

**Example Input:**
```json
{
  "base_topics": ["coding tutorials", "software development", "tech career advice"],
  "expansion_factor": 7,
  "min_score_threshold": 5.0,
  "platform": "youtube"
}
```

**Expected Output:** Comprehensive topic research report with clusters focused on high-opportunity programming tutorial topics, competitive landscape analysis of existing coding channels, and strategic recommendations for content differentiation.

### Use Case 2: Content Refresh for Existing Channel

**Scenario:** Refreshing content strategy for an established channel experiencing performance plateau

**Example Input:**
```json
{
  "base_topics": ["data science", "python programming", "AI applications"],
  "competitor_channels": ["StatQuest", "3Blue1Brown", "Corey Schafer"],
  "expansion_factor": 3,
  "min_score_threshold": 6.0
}
```

**Expected Output:** Gap analysis identifying untapped opportunities within the channel's existing niche, competitive differentiation strategies against specified competitors, and recommendations for content series that can revitalize channel growth.

## Implementation Notes

### Technical Details

- Topic analysis leverages a fine-tuned Sentence Transformer model for embeddings
- Clustering uses UMAP for dimensionality reduction followed by K-means
- YouTube API v3 provides video and channel metadata
- Google Trends API supplements search interest data
- DuckDB provides local persistence for analysis results

### Deployment Considerations

- Requires API keys for YouTube Data API and optional Google Trends API
- Embedding models should be pre-loaded or cached for performance
- Consider implementing request quotas to prevent API limit exhaustion
- Database persistence recommended for high-volume usage

## Current Limitations

- Limited to textual topic analysis (cannot analyze visual content trends)
- Search volume data may have accuracy limitations for emerging topics
- YouTube API quotas restrict the number of analyzable competitors
- English-language focus limits effectiveness for multilingual content
- Historical trend data limited to available API endpoints

## Future Enhancements

- Multi-platform topic analysis across YouTube, TikTok, and Instagram
- Integration with content production systems for automated brief creation
- Machine learning models for performance prediction by topic
- Visual content trend analysis through computer vision
- Audience sentiment analysis through comment processing
- Real-time trend alerting for emerging topics

## Related Workflows

- [Content Explorer Workflow](./content-explorer-workflow.md)
- [Niche Scout Workflow](./niche-scout-workflow-migrated.md)
- [Seed to Blueprint Workflow](./seed-to-blueprint-workflow-migrated.md)

## References

- [YouTube Data API Documentation](https://developers.google.com/youtube/v3/docs)
- [Social Intelligence Agent Documentation](../../agents/social-intel/agent.md)
- [Content Strategy Framework](../../docs/projects/content-factory/content-strategy-framework.md)