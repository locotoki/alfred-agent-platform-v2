#!/usr/bin/env python
"""Manual test script for YouTube-focused flows in SocialIntelligence Agent."""

import argparse
import asyncio
import json
import os

# Add parent directory to path
import sys
from datetime import datetime

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import agent
from agents.social_intel.flows.youtube_flows import (
    youtube_blueprint_flow,
    youtube_niche_scout_flow,
)


async def test_niche_scout(queries=None):
    """Test YouTube Niche-Scout workflow."""
    if not queries:
        queries = [
            "nursery rhymes",
            "diy woodworking",
            "urban gardening",
            "ai news",
            "budget travel",
        ]

    print(f"Running Niche Scout with queries: {queries}")

    result = await youtube_niche_scout_flow(queries=queries)

    # Print results
    print("\n=== Niche Scout Results ===")
    print(f"Run Date: {result.run_date}")
    print(f"Total Niches: {len(result.trending_niches)}")

    if result.top_niches:
        print("\nTop Niches:")
        for i, niche in enumerate(result.top_niches[:3], 1):
            print(f"{i}. {niche.query} - Score: {niche.score:.2f}")

    # Read digest
    digest_path = os.path.join("niche_scout", "digest.md")
    if os.path.exists(digest_path):
        with open(digest_path, "r") as f:
            digest = f.read()
        print("\nDigest Preview:")
        print(digest[:500] + "..." if len(digest) > 500 else digest)

    return result


async def test_blueprint(seed_url=None, auto_niche=False):
    """Test Seed-to-Blueprint workflow."""
    if not seed_url and not auto_niche:
        seed_url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"  # Example video

    print(
        f"Running Blueprint with seed URL: {seed_url if seed_url else 'Auto-selected from niches'}"
    )

    result = await youtube_blueprint_flow(seed_url=seed_url, auto_niche=auto_niche)

    # Print results
    print("\n=== Blueprint Results ===")
    print(f"Run Date: {result.run_date}")
    print(f"Seed URL: {result.seed_url}")

    if result.top_channels:
        print("\nTop Channels:")
        for i, channel in enumerate(result.top_channels[:3], 1):
            print(f"{i}. {channel.channel_name} - {channel.subscribers:,} subscribers")

    if result.blueprint:
        print("\nBlueprint Preview:")
        print(f"Positioning: {result.blueprint.positioning[:100]}...")
        print(f"Content Pillars: {', '.join(result.blueprint.content_pillars)}")

    print(f"\nBlueprint URL: {result.blueprint_url}")

    return result


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Test YouTube agent workflows")

    # Add arguments
    parser.add_argument(
        "--workflow",
        choices=["niche_scout", "blueprint", "both"],
        default="both",
        help="Which workflow to test",
    )

    parser.add_argument("--queries", nargs="+", help="Queries for Niche Scout")

    parser.add_argument("--seed-url", help="Seed URL for Blueprint")

    parser.add_argument("--auto-niche", action="store_true", help="Auto-select niche for Blueprint")

    return parser.parse_args()


async def main():
    """Main function."""
    args = parse_args()

    # Create output directories
    os.makedirs("niche_scout", exist_ok=True)
    os.makedirs("builder", exist_ok=True)

    if args.workflow in ["niche_scout", "both"]:
        await test_niche_scout(args.queries)

    if args.workflow in ["blueprint", "both"]:
        await test_blueprint(args.seed_url, args.auto_niche)


if __name__ == "__main__":
    asyncio.run(main())
