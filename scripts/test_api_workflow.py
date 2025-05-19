#!/usr/bin/env python
"""Test script for YouTube workflows via the API."""

import argparse
import time
from datetime import datetime

import requests


def test_niche_scout(host="localhost", port=9000):
    """Test the Niche-Scout workflow via API."""
    url = f"http://{host}:{port}/api/tasks"

    # Create task payload
    payload = {
        "intent": "YOUTUBE_NICHE_SCOUT",
        "data": {
            "queries": [
                "nursery rhymes",
                "diy woodworking",
                "urban gardening",
                "ai news",
                "budget travel",
            ]
        },
        "trace_id": f"trace_{datetime.now().isoformat()}",
    }

    # Post task
    response = requests.post(url, json=payload)

    if response.status_code != 200:
        print(f"Error: {response.status_code}")
        print(response.text)
        return None

    task_id = response.json().get("task_id")
    print(f"Task created: {task_id}")

    # Poll for results
    result_url = f"http://{host}:{port}/api/tasks/{task_id}"
    max_attempts = 60
    attempts = 0

    while attempts < max_attempts:
        response = requests.get(result_url)

        if response.status_code != 200:
            print(f"Error: {response.status_code}")
            print(response.text)
            return None

        data = response.json()
        status = data.get("status")

        if status == "completed":
            print("Task completed successfully!")
            return data

        if status == "failed":
            print(f"Task failed: {data.get('error')}")
            return None

        print(f"Status: {status}, waiting...")
        attempts += 1
        time.sleep(5)

    print("Timeout waiting for task completion")
    return None


def test_blueprint(seed_url=None, auto_niche=False, host="localhost", port=9000):
    """Test the Blueprint workflow via API."""
    url = f"http://{host}:{port}/api/tasks"

    # Create task payload
    payload = {
        "intent": "YOUTUBE_BLUEPRINT",
        "data": {"auto_niche": auto_niche},
        "trace_id": f"trace_{datetime.now().isoformat()}",
    }

    if seed_url:
        payload["data"]["seed_url"] = seed_url

    # Post task
    response = requests.post(url, json=payload)

    if response.status_code != 200:
        print(f"Error: {response.status_code}")
        print(response.text)
        return None

    task_id = response.json().get("task_id")
    print(f"Task created: {task_id}")

    # Poll for results
    result_url = f"http://{host}:{port}/api/tasks/{task_id}"
    max_attempts = 120  # Longer timeout for blueprint
    attempts = 0

    while attempts < max_attempts:
        response = requests.get(result_url)

        if response.status_code != 200:
            print(f"Error: {response.status_code}")
            print(response.text)
            return None

        data = response.json()
        status = data.get("status")

        if status == "completed":
            print("Task completed successfully!")
            return data

        if status == "failed":
            print(f"Task failed: {data.get('error')}")
            return None

        print(f"Status: {status}, waiting...")
        attempts += 1
        time.sleep(5)

    print("Timeout waiting for task completion")
    return None


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Test YouTube agent API workflows")

    # Add arguments
    parser.add_argument(
        "--workflow",
        choices=["niche_scout", "blueprint", "both"],
        default="both",
        help="Which workflow to test",
    )

    parser.add_argument("--seed-url", help="Seed URL for Blueprint")

    parser.add_argument("--auto-niche", action="store_true", help="Auto-select niche for Blueprint")

    parser.add_argument("--host", default="localhost", help="API host")

    parser.add_argument("--port", type=int, default=9000, help="API port")

    return parser.parse_args()


def main():
    """Main function."""
    args = parse_args()

    if args.workflow in ["niche_scout", "both"]:
        print("\n=== Testing Niche-Scout Workflow ===\n")
        niche_result = test_niche_scout(args.host, args.port)

        if niche_result:
            print("\nNiche Scout Result:")
            top_niches = niche_result.get("data", {}).get("top_niches", [])
            for i, niche in enumerate(top_niches[:3], 1):
                print(f"{i}. {niche.get('query')} - Score: {niche.get('score')}")

    if args.workflow in ["blueprint", "both"]:
        print("\n=== Testing Blueprint Workflow ===\n")
        blueprint_result = test_blueprint(args.seed_url, args.auto_niche, args.host, args.port)

        if blueprint_result:
            print("\nBlueprint Result:")
            blueprint = blueprint_result.get("data", {}).get("blueprint", {})
            print(f"Positioning: {blueprint.get('positioning', '')[:100]}...")
            print(f"Content Pillars: {', '.join(blueprint.get('content_pillars', []))}")
            print(f"Blueprint URL: {blueprint_result.get('data', {}).get('blueprint_url', '')}")


if __name__ == "__main__":
    main()
