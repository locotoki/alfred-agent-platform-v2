#!/usr/bin/env python3
"""
Test script for validating the YouTube API key configuration.

This script tests if the configured YouTube API key is valid and has access to the
required YouTube Data API v3 endpoints that our application uses.

Usage:
    python test_youtube_api_key.py [--api-key API_KEY]

Options:
    --api-key API_KEY   YouTube API key to test (default: read from .env file)
"""

import argparse
import os
import sys
from typing import Any, Dict, List, Optional

import dotenv
import requests

YOUTUBE_API_BASE_URL = "https://www.googleapis.com/youtube/v3"


def load_api_key_from_env() -> Optional[str]:
    """Load YouTube API key from .env file."""
    # Try to load from .env file
    dotenv.load_dotenv()
    return os.environ.get("YOUTUBE_API_KEY")


def test_search_endpoint(api_key: str) -> Dict[str, Any]:
    """Test the YouTube API search endpoint.

    Args:
        api_key: YouTube API key to use for the request.

    Returns:
        Dictionary with test results.
    """
    url = f"{YOUTUBE_API_BASE_URL}/search"
    params = {
        "part": "snippet",
        "q": "nursery rhymes for toddlers",
        "type": "video",
        "maxResults": 5,
        "key": api_key,
    }

    try:
        response = requests.get(url, params=params)
        status_code = response.status_code

        if status_code == 200:
            data = response.json()
            item_count = len(data.get("items", []))
            return {
                "success": True,
                "status_code": status_code,
                "items_found": item_count,
                "quota_used": 100,  # Search request costs 100 units
            }
        else:
            error_data = response.json() if response.text else {"error": "Unknown error"}
            return {
                "success": False,
                "status_code": status_code,
                "error": error_data.get("error", {}).get("message", "Unknown error"),
                "quota_used": 0,
            }
    except Exception as e:
        return {"success": False, "status_code": 0, "error": str(e), "quota_used": 0}


def test_videos_endpoint(api_key: str) -> Dict[str, Any]:
    """Test the YouTube API videos endpoint.

    Args:
        api_key: YouTube API key to use for the request.

    Returns:
        Dictionary with test results.
    """
    url = f"{YOUTUBE_API_BASE_URL}/videos"
    params = {
        "part": "snippet,statistics",
        "chart": "mostPopular",
        "regionCode": "US",
        "maxResults": 5,
        "key": api_key,
    }

    try:
        response = requests.get(url, params=params)
        status_code = response.status_code

        if status_code == 200:
            data = response.json()
            item_count = len(data.get("items", []))
            return {
                "success": True,
                "status_code": status_code,
                "items_found": item_count,
                "quota_used": 1,  # Videos request costs 1 unit per video part
            }
        else:
            error_data = response.json() if response.text else {"error": "Unknown error"}
            return {
                "success": False,
                "status_code": status_code,
                "error": error_data.get("error", {}).get("message", "Unknown error"),
                "quota_used": 0,
            }
    except Exception as e:
        return {"success": False, "status_code": 0, "error": str(e), "quota_used": 0}


def test_channels_endpoint(api_key: str) -> Dict[str, Any]:
    """Test the YouTube API channels endpoint.

    Args:
        api_key: YouTube API key to use for the request.

    Returns:
        Dictionary with test results.
    """
    url = f"{YOUTUBE_API_BASE_URL}/channels"
    params = {"part": "snippet,statistics", "forUsername": "Google", "key": api_key}

    try:
        response = requests.get(url, params=params)
        status_code = response.status_code

        if status_code == 200:
            data = response.json()
            item_count = len(data.get("items", []))
            return {
                "success": True,
                "status_code": status_code,
                "items_found": item_count,
                "quota_used": 1,  # Channels request costs 1 unit per channel part
            }
        else:
            error_data = response.json() if response.text else {"error": "Unknown error"}
            return {
                "success": False,
                "status_code": status_code,
                "error": error_data.get("error", {}).get("message", "Unknown error"),
                "quota_used": 0,
            }
    except Exception as e:
        return {"success": False, "status_code": 0, "error": str(e), "quota_used": 0}


def run_all_tests(api_key: str) -> List[Dict[str, Any]]:
    """Run all YouTube API tests.

    Args:
        api_key: YouTube API key to use for the tests.

    Returns:
        List of test results.
    """
    results = []

    print(f"Testing YouTube API key: {api_key[:5]}...{api_key[-5:]}")

    # Test search endpoint
    print("\nTesting search endpoint...")
    search_result = test_search_endpoint(api_key)
    print(f"Success: {search_result['success']}")
    if search_result["success"]:
        print(f"Found {search_result['items_found']} items")
    else:
        print(f"Error: {search_result.get('error', 'Unknown error')}")
    results.append({"endpoint": "search", "result": search_result})

    # Test videos endpoint
    print("\nTesting videos endpoint...")
    videos_result = test_videos_endpoint(api_key)
    print(f"Success: {videos_result['success']}")
    if videos_result["success"]:
        print(f"Found {videos_result['items_found']} items")
    else:
        print(f"Error: {videos_result.get('error', 'Unknown error')}")
    results.append({"endpoint": "videos", "result": videos_result})

    # Test channels endpoint
    print("\nTesting channels endpoint...")
    channels_result = test_channels_endpoint(api_key)
    print(f"Success: {channels_result['success']}")
    if channels_result["success"]:
        print(f"Found {channels_result['items_found']} items")
    else:
        print(f"Error: {channels_result.get('error', 'Unknown error')}")
    results.append({"endpoint": "channels", "result": channels_result})

    # Calculate total quota used
    total_quota = sum(r["result"].get("quota_used", 0) for r in results)
    print(f"\nTotal quota used: {total_quota} units")

    # Check overall success
    all_success = all(r["result"].get("success", False) for r in results)
    print(f"Overall success: {all_success}")

    return results


def main():
    parser = argparse.ArgumentParser(description="Test YouTube API key")
    parser.add_argument("--api-key", help="YouTube API key to test")

    args = parser.parse_args()

    # Get API key from arguments or .env file
    api_key = args.api_key or load_api_key_from_env()

    if not api_key:
        print(
            "Error: No YouTube API key provided. Use --api-key option or set YOUTUBE_API_KEY in .env file."
        )
        sys.exit(1)

    results = run_all_tests(api_key)

    # Exit with status code based on success
    all_success = all(r["result"].get("success", False) for r in results)
    sys.exit(0 if all_success else 1)


if __name__ == "__main__":
    main()
