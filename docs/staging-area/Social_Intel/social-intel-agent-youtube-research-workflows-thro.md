# Social Intel Agent : YouTube research workflows through simple API calls

You can use the YouTube research workflows through simple API calls. Here's how to use each one:

1. Niche-Scout Workflow

This workflow finds fast-growing, Shorts-friendly YouTube niches.

# Basic usage with no query (analyzes general trends)

curl -X POST "[http://localhost:9000/niche-scout](http://localhost:9000/niche-scout)"

# Search for gaming niches

curl -X POST "[http://localhost:9000/niche-scout?query=gaming](http://localhost:9000/niche-scout?query=gaming)"

# Search for cooking niches

curl -X POST "[http://localhost:9000/niche-scout?query=cooking](http://localhost:9000/niche-scout?query=cooking)"

The response will include:

- List of trending niches with growth rates and demographics
- Content topics that are currently performing well
- Top channels in each niche
- Analysis summary with recommendations
- File paths to the saved reports
1. Seed-to-Blueprint Workflow

This workflow creates a channel strategy based on a seed video or niche.

# Create a blueprint based on a YouTube video

curl -X POST "[http://localhost:9000/seed-to-blueprint?video_url=https://www.youtube.com/watch?v=example123](http://localhost:9000/seed-to-blueprint?video_url=https://www.youtube.com/watch?v=example123)"

# Create a blueprint based on a niche instead of a video

curl -X POST "[http://localhost:9000/seed-to-blueprint?niche=gaming](http://localhost:9000/seed-to-blueprint?niche=gaming)"

The response will include:

- Competitor analysis with strengths and weaknesses
- Content gap opportunities
- Channel strategy with name ideas and content pillars
- Posting schedule recommendations
- 30-day and 90-day execution plans
- File paths to the saved reports

All results are automatically saved as JSON files in the container's data directories:

- Niche Scout reports: /app/data/niche_scout/
- Blueprint reports: /app/data/builder/
