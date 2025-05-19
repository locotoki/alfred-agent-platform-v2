# SocialIntelligence Agent - YouTube Module

This document describes the YouTube functionality implemented within the SocialIntelligence Agent.

## Overview

The YouTube module adds two main workflows to the SocialIntelligence Agent:

1. **Niche-Scout**: Automatically identifies and ranks trending YouTube niches based on view metrics and Google Trends data.
2. **Seed-to-Blueprint**: Generates a complete YouTube channel strategy from a seed video, including competitor analysis, content gap identification, and a 30-day content roadmap.

## Intents

The agent supports the following YouTube-specific intents:

- `YOUTUBE_NICHE_SCOUT`: Runs the Niche-Scout workflow to find trending niches.
- `YOUTUBE_BLUEPRINT`: Runs the Seed-to-Blueprint workflow to create a channel strategy.

## Architecture

### Components

- **YouTube API**: Integrates with YouTube search and metadata APIs using `youtube-search-python` and `yt-dlp`.
- **Vector Storage**: Stores and retrieves YouTube-related vectors using Qdrant (primary) and pgvector in Supabase (secondary).
- **Prefect Flows**: Orchestrates the complex workflows with proper task dependencies.
- **Models**: Pydantic models for YouTube entities (niches, videos, channels, blueprints).

### Data Flow

```
1. A2A Envelope → SocialIntelAgent → YouTube Flow → Result
2. Result stored in vector databases for future reference
3. Output files generated in niche_scout/ and builder/ directories
```

## Installation

The SocialIntelligence Agent requires the following dependencies for YouTube functionality:

```
yt-dlp==2024.3.10
youtube-search-python==1.6.6
pytrends==4.9.0
duckdb==0.9.2
umap-learn==0.5.4
sentence-transformers==2.2.2
scikit-learn==1.4.0
matplotlib==3.8.2
prefect==2.14.5
```

These are automatically installed when building the Docker container.

## Usage

### Niche-Scout

Example A2A envelope:

```json
{
  "intent": "YOUTUBE_NICHE_SCOUT",
  "data": {
    "queries": [
      "nursery rhymes",
      "diy woodworking",
      "urban gardening",
      "ai news",
      "budget travel"
    ]
  }
}
```

### Seed-to-Blueprint

Example A2A envelope:

```json
{
  "intent": "YOUTUBE_BLUEPRINT",
  "data": {
    "seed_url": "https://www.youtube.com/watch?v=VIDEO_ID",
    "auto_niche": false
  }
}
```

To auto-select a trending niche (instead of providing a seed URL):

```json
{
  "intent": "YOUTUBE_BLUEPRINT",
  "data": {
    "auto_niche": true
  }
}
```

## Testing

Run the test script:

```bash
python scripts/test_youtube_agent.py --workflow both
```

Or run specific tests:

```bash
# Test just Niche-Scout
python scripts/test_youtube_agent.py --workflow niche_scout --queries "cooking tips" "home automation"

# Test Blueprint with a specific video
python scripts/test_youtube_agent.py --workflow blueprint --seed-url "https://www.youtube.com/watch?v=VIDEO_ID"

# Test Blueprint with auto-niche selection
python scripts/test_youtube_agent.py --workflow blueprint --auto-niche
```

## Integration with Mission Control UI

The YouTube functionality has been integrated into the Mission Control UI with the following components:

### Workflow Detail Pages

- **Niche Scout** (`/workflows/niche-scout/index.tsx`):
  - Form for entering search queries
  - Advanced options for category, time range, and demographics

- **Seed-to-Blueprint** (`/workflows/seed-to-blueprint/index.tsx`):
  - Input for video URL or niche
  - Advanced options for analysis depth

### Result Pages

- **Niche Scout Results** (`/workflows/niche-scout/results/[id].tsx`):
  - Overview, trending niches, and visualization tabs

- **Seed-to-Blueprint Results** (`/workflows/seed-to-blueprint/results/[id].tsx`):
  - Tabs for blueprint, competitors, gap analysis, and AI tips

### API Integration

The Mission Control UI communicates with the SocialIntelligence Agent through proxy handlers:

- `/api/social-intel/niche-scout.ts`
- `/api/social-intel/seed-to-blueprint.ts`
- `/api/social-intel/workflow-history.ts`
- `/api/social-intel/workflow-result/[id].ts`
- `/api/social-intel/scheduled-workflows.ts`
- `/api/social-intel/schedule-workflow.ts`

The implementation includes proper error handling and fallback mock data for development and testing.

## Data Storage

- **Temporary Files**: Stored in `niche_scout/` and `builder/` directories
- **Vector Embeddings**:
  - Long-term storage in Qdrant collections: `youtube_channels`, `youtube_videos`, `youtube_niches`
  - Ephemeral embeddings in pgvector table: `yt_ephemeral_embeddings`

## Future Enhancements

1. Add real-time trend monitoring via scheduled Prefect flows
2. Implement comment sentiment analysis for deeper audience insights
3. Add support for TikTok and Instagram Reels comparison
4. Integrate with content scheduling tools via n8n
