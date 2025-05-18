# Niche-Scout Transformation Pipeline

## Overview

This document describes the enhanced transformation pipeline implemented in Phase 0 of the Niche-Scout ↔ Social-Intel Integration project. It serves as a guide for Phase 1 implementation, where the transformation logic will be moved to a proxy service.

## Pipeline Architecture

The enhanced transformation pipeline consists of several modular stages that can be extracted and reused in the proxy service. The diagram below illustrates the data flow:

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│                │     │                │     │                │     │                │
│  API Response  │────▶│  Niche         │────▶│  Channel       │────▶│  Analysis      │
│  Transformation│     │  Generation    │     │  Generation    │     │  Generation    │
│                │     │                │     │                │     │                │
└────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘
        │                      │                      │                      │
        ▼                      ▼                      ▼                      ▼
┌────────────────┐     ┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│                │     │                │     │                │     │                │
│  Input         │     │  Multi-Algo    │     │  Topic         │     │  Detailed      │
│  Validation    │     │  Similarity    │     │  Generation    │     │  Metrics       │
│                │     │                │     │                │     │                │
└────────────────┘     └────────────────┘     └────────────────┘     └────────────────┘
```

## Enhanced Key Components

### 1. Enhanced API Response Transformation (`callNicheScout`)

**Purpose**: Determines if API response needs transformation and applies the transformation pipeline if needed, with detailed step timing.

**Inputs**:
- `params`: User search parameters (query, category, etc.)
- API response data from Social Intelligence

**Outputs**:
- Transformed data with relevant niches and metadata
- Detailed performance metrics for each step

**Extraction Points**:
- Move the transformation logic to the proxy service's `POST /workflows/niche-scout` endpoint
- Keep the API call and response handling in the proxy
- Extract step timing mechanism for monitoring

**Enhancements**:
- Step-by-step performance tracking
- Intelligent fallback system
- Comprehensive transformation metadata

### 2. Enhanced Niche Generation (`getMockNichesForCategory`)

**Purpose**: Generates highly relevant niches based on search parameters using multiple scoring factors.

**Inputs**:
- `query`: User search query
- `category`: Content category
- Category lists from external JSON file

**Outputs**:
- Array of relevant niche names
- Performance statistics for the generation process

**Extraction Points**:
- Move to the proxy service as a standalone function
- Configure the external category lists as a deployable JSON file
- Extract the scoring logic as a configurable module

**Enhancements**:
- Multi-word query handling
- Category-specific semantic templates
- Comprehensive relevance scoring
- Performance tracking

### 3. Multi-Algorithm String Similarity (`stringSimilarity`)

**Purpose**: Calculates similarity between strings using a weighted combination of algorithms.

**Inputs**:
- `str1`: First string to compare
- `str2`: Second string to compare

**Outputs**:
- Similarity score between 0 and 1

**Extraction Points**:
- Extract as a utility in the proxy service
- Add configuration for similarity algorithm weights and thresholds

**Enhancements**:
- Combined Levenshtein, Jaccard, and Jaro-Winkler algorithms
- Special handling for short strings and substrings
- Optimized early exit patterns
- Word-level matching for multi-word strings

### 4. Context-Aware Channel Generation (`generateChannelNames`)

**Purpose**: Creates realistic channel names based on niche and category context.

**Inputs**:
- `nicheName`: Name of the niche
- `originalNiche`: Original niche data (if available)
- `category`: Content category

**Outputs**:
- Array of channel objects with name and subscriber counts

**Extraction Points**:
- Extract as a standalone service in the proxy
- Configure naming patterns as JSON settings

**Enhancements**:
- Category-specific naming patterns
- Primary word extraction and prioritization
- Multi-word combination handling
- Realistic subscriber count distribution

### 5. Enhanced Topic Generation (`getTopicsForNiche`)

**Purpose**: Generates trending topics for a specific niche based on keywords and category.

**Inputs**:
- `nicheName`: Name of the niche

**Outputs**:
- Array of relevant trending topics

**Extraction Points**:
- Extract as a standalone service in the proxy
- Consider moving topic maps to configurable JSON

**Enhancements**:
- More comprehensive topic categories
- Better keyword extraction and matching
- Improved topic variation

### 6. Comprehensive Metrics Collection (`logTransformationMetrics`)

**Purpose**: Collects and stores detailed transformation metrics with quality assessment.

**Inputs**:
- `originalData`: Original API response
- `transformedData`: Transformed data
- `searchParams`: User search parameters
- `startTime`: Performance timing start
- `additionalMetrics`: Optional metrics

**Outputs**:
- Comprehensive metrics object with performance, relevance, and quality data

**Extraction Points**:
- Replace localStorage with Prometheus metrics
- Move the event dispatch mechanism to the proxy service
- Extract metrics calculation functions as separate modules

**Enhancements**:
- Data quality assessment
- Relevance improvement measurement
- Similarity distribution tracking
- Prometheus-compatible metrics format
- Comprehensive performance tracking

### 7. Contextual Recommendation Generation (`generateRecommendations`)

**Purpose**: Creates meaningful, context-aware recommendations based on analysis and parameters.

**Inputs**:
- `summary`: Analysis summary with top niches
- `params`: Search parameters
- `niches`: Transformed niches

**Outputs**:
- Array of recommendation strings

**Extraction Points**:
- Extract as a standalone service in the proxy
- Configure recommendation templates as JSON settings

**Enhancements**:
- Category-specific recommendation patterns
- Competition and growth-based suggestions
- Content format recommendations

## Customization Points

The enhanced pipeline includes several customization points that should be exposed in the proxy service:

1. **Similarity Threshold**: Currently set to `SIMILARITY_THRESHOLD` (0.55)
2. **Algorithm Weights**: The weights in the combined similarity score (Levenshtein: 0.5, Jaccard: 0.3, Jaro-Winkler: 0.2)
3. **Category Lists**: External JSON file containing category-specific niches
4. **Default Niche Count**: Number of niches to generate (currently `DEFAULT_NICHE_COUNT` = 5)
5. **Channel Name Patterns**: Category-specific channel name formats
6. **Topic Templates**: Keyword-based topic patterns

## Implementation Notes for Phase 1

### Data Storage

1. **Category Lists**: Store in Redis with version tracking
2. **Metrics**: Use Prometheus with the following metrics:
   - `proxy_transform_duration_ms` (Histogram)
   - `proxy_relevance_score` (Gauge)
   - `proxy_relevant_niche_count` (Gauge)
   - `proxy_match_types` (Counter with labels)
   - `proxy_data_quality_score` (Gauge)
   - `proxy_transformation_complexity` (Gauge)
   - `proxy_relevance_improvement` (Gauge)

### API Contract

The proxy service should maintain the same API contract as Phase 0, with enhanced metadata:

```javascript
// Request
{
  "query": "mobile",
  "category": "Gaming",
  "subcategories": ["Mobile Gaming"],
  "timeRange": "Last 30 days",
  "demographics": "All"
}

// Response
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
    "Target trending topics like Game development tutorials",
    "Consider short-form vertical content for Mobile Gaming"
  ],
  "meta": {
    "transformation_version": "phase1-v1",
    "processing_time_ms": 42,
    "relevance_score": 0.87,
    "cache_hit": true,
    "data_quality_score": 0.95,
    "transformation_complexity": "medium",
    "step_timings": {
      "api_call": 2000.2,
      "data_analysis": 0.4,
      "niche_generation": 1.2,
      "niche_transformation": 1.4,
      "summary_generation": 0.5
    }
  }
}
```

### Testing Strategy

1. **Unit Tests**: Port the existing unit tests to the proxy service
2. **Contract Tests**: Add tests for the API contract
3. **Performance Tests**: Benchmark the proxy service under load
4. **Caching Tests**: Verify Redis caching behavior
5. **Quality Tests**: Verify the data quality assessment
6. **Relevance Tests**: Validate the relevance scoring across diverse queries

## Transition Plan

1. **Extract Functions**: Move the enhanced transformation pipeline to the proxy service
2. **Add Configuration**: Make thresholds, weights, and category lists configurable
3. **Implement Metrics**: Replace localStorage with Prometheus
4. **Deploy Alongside**: Run the proxy service alongside the client-side transformation
5. **Gradual Rollout**: Use feature flags to control traffic between client-side and proxy
6. **Monitoring Setup**: Configure dashboards for the new metrics

## Version History

- v1.0.0: Initial pipeline documentation for Phase 0
- v1.1.0: Added extraction points and customization notes for Phase 1
- v2.0.0: Updated with enhanced pipeline components and implementation details
