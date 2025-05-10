#!/bin/bash

# Test script to run inside the social-intel container

# Install required packages
pip install yt-dlp==2024.3.10 youtube-search-python==1.6.6 pytrends==4.9.0 duckdb==0.9.2 umap-learn==0.5.4 scikit-learn==1.4.0 sentence-transformers==2.2.2 prefect==2.14.5 matplotlib pandas

# Create test directories
mkdir -p /app/niche_scout /app/builder

# Create a simple test script
cat > /app/test_niche_scout.py << 'EOL'
#!/usr/bin/env python
"""Simple test script for YouTube Niche-Scout workflow."""

import asyncio
import os
import json
import pandas as pd
import numpy as np
from datetime import datetime
import umap
import sklearn.cluster as skc
from youtubesearchpython import VideosSearch
from pytrends.request import TrendReq

async def search_videos(query, limit=100):
    """Search for videos using the given query."""
    print(f"Searching for videos: {query}")
    try:
        search_result = VideosSearch(query, limit=limit).result()
        videos = search_result.get('result', [])
        print(f"Found {len(videos)} videos")
        return videos
    except Exception as e:
        print(f"Error searching videos: {str(e)}")
        return []

async def get_trend_data(query, timeframe='now 7-d'):
    """Get Google Trends data for a query."""
    print(f"Getting trend data for: {query}")
    try:
        py_trends = TrendReq(hl="en-US", tz=0)
        py_trends.build_payload([query], timeframe=timeframe)
        trend_data = py_trends.interest_over_time()
        
        if query not in trend_data:
            print(f"No trend data found for {query}")
            return None
            
        # Extract the trend series and create a result dictionary
        trend_series = trend_data[query]
        
        # Calculate metrics
        current_value = trend_series.iloc[-1]
        week_avg = trend_series.mean()
        
        result = {
            "query": query,
            "timeframe": timeframe,
            "current_value": float(current_value),
            "week_avg": float(week_avg)
        }
        
        print(f"Trend data retrieved for {query}")
        return result
    except Exception as e:
        print(f"Error getting trend data: {str(e)}")
        return None

async def harvest_youtube_signals(queries):
    """Harvest signals from YouTube and Google Trends."""
    print("Harvesting YouTube signals...")
    rows = []
    today = datetime.now().date().isoformat()
    
    for q in queries:
        # Get videos for this query
        videos = await search_videos(q, limit=10)  # Reduced for testing
        
        # Calculate total views
        view_sum = sum(
            int(v.get('viewCount', {}).get('text', '0').replace(',', '')) 
            if isinstance(v.get('viewCount'), dict) else 0 
            for v in videos
        )
        
        # Get trend data
        trend_data = await get_trend_data(q)
        rsv = trend_data["current_value"] if trend_data else 0
        
        # Add to results
        rows.append((today, q, view_sum, rsv))
        
        # Sleep to avoid rate limiting
        await asyncio.sleep(1)
    
    # Create DataFrame
    df = pd.DataFrame(rows, columns=["date", "query", "view_sum", "rsv"])
    
    return df

def score_cluster_niches(signals_df):
    """Score and cluster the niches."""
    print("Scoring and clustering niches...")
    # Get latest date data
    latest = signals_df[signals_df.date == signals_df.date.max()].copy()
    
    # Rank niches
    latest['view_rank'] = latest.view_sum.rank(ascending=False)
    latest['rsv_rank'] = latest.rsv.rank(ascending=False)
    
    # Calculate combined score (weighted)
    latest['score'] = 0.6 * latest['view_rank'] + 0.4 * latest['rsv_rank']
    
    # Create UMAP embeddings for visualization and clustering
    embeddings = umap.UMAP(
        n_components=2, 
        random_state=42
    ).fit_transform(pd.get_dummies(latest['query']))
    
    latest[['x', 'y']] = embeddings
    
    # Cluster similar niches
    n_clusters = min(3, len(latest))
    if n_clusters > 1:  # Ensure we have enough data to cluster
        clusters = skc.KMeans(n_clusters=n_clusters).fit(embeddings)
        latest['niche'] = clusters.labels_
    else:
        latest['niche'] = 0
    
    # Save to CSV
    os.makedirs("niche_scout", exist_ok=True)
    latest.to_csv("niche_scout/trending_niches.csv", index=False)
    
    print("Saved trending niches to niche_scout/trending_niches.csv")
    return latest

def generate_niche_scout_digest(trending_niches):
    """Generate a digest of the top niches."""
    print("Generating niche scout digest...")
    # Sort by score and get top niches
    top_niches = trending_niches.sort_values("score", ascending=False)
    
    # Create summary text
    summary = [
        f"# YouTube Niche Scout - {datetime.now().strftime('%Y-%m-%d')}\n\n",
        "## Top Trending Niches\n\n"
    ]
    
    for i, (_, niche) in enumerate(top_niches.iterrows(), 1):
        summary.append(
            f"{i}. **{niche.query}** - Score: {niche.score:.2f} - "
            f"Views: {niche.view_sum:,} - Trend Value: {niche.rsv:.2f}\n"
        )
    
    # Add cluster information
    summary.append("\n## Niche Clusters\n\n")
    
    clusters = trending_niches.groupby("niche")
    for cluster_id, group in clusters:
        top_in_cluster = group.sort_values("score", ascending=False)
        
        summary.append(f"Cluster {cluster_id}: ")
        summary.append(", ".join(top_in_cluster.query.tolist()))
        summary.append("\n")
    
    digest = "".join(summary)
    
    # Save digest to file
    with open("niche_scout/digest.md", "w") as f:
        f.write(digest)
    
    print("Saved digest to niche_scout/digest.md")
    return digest

async def run_niche_scout():
    """Run the YouTube Niche-Scout workflow."""
    print("Starting Niche Scout workflow...")
    
    # Test queries
    queries = [
        "nursery rhymes", 
        "diy woodworking", 
        "urban gardening", 
        "ai news", 
        "budget travel"
    ]
    
    # Run workflow
    signals_df = await harvest_youtube_signals(queries)
    print("Signal summary:")
    print(signals_df)
    
    trending_niches = score_cluster_niches(signals_df)
    print("\nTop trending niches:")
    print(trending_niches.sort_values("score", ascending=False)[["query", "view_sum", "rsv", "score", "niche"]])
    
    digest = generate_niche_scout_digest(trending_niches)
    print("\nDigest preview:")
    print(digest[:500] + "..." if len(digest) > 500 else digest)
    
    print("\nNiche Scout workflow completed successfully!")

if __name__ == "__main__":
    asyncio.run(run_niche_scout())
EOL

# Run the test script
python /app/test_niche_scout.py

# Output results
echo "Test complete! Check the niche_scout directory for results."
echo "trending_niches.csv:"
cat /app/niche_scout/trending_niches.csv
echo
echo "digest.md:"
cat /app/niche_scout/digest.md