#!/usr/bin/env python3
"""
Test script for the Niche-Scout workflow API.

This script tests the Social Intelligence Service API endpoint for the Niche-Scout workflow.
It sends various test cases with different categories and subcategories to verify the API
is functioning properly.

Usage:
    python test_niche_scout_api.py [--base-url URL] [--mock]

Options:
    --base-url URL    Base URL of the Social Intelligence Service (default: http://localhost:9000)
    --mock            Use mock data instead of making real API calls
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime
from typing import Any, Dict, Optional

import requests

# Test cases with various categories and subcategories
TEST_CASES = [
    {
        "name": "Default Query",
        "query": None,
        "category": None,
        "subcategory": None,
        "expected_status": 200,
    },
    {
        "name": "Gaming Category",
        "query": "gaming tips",
        "category": "tech",
        "subcategory": "tech.gaming",
        "expected_status": 200,
    },
    {
        "name": "Kids Nursery Rhymes",
        "query": "nursery rhymes for toddlers",
        "category": "kids",
        "subcategory": "kids.nursery",
        "expected_status": 200,
    },
    {
        "name": "Cooking Recipes",
        "query": "easy dinner recipes",
        "category": "lifestyle",
        "subcategory": "lifestyle.food",
        "expected_status": 200,
    },
    {
        "name": "Invalid Query",
        "query": "!" * 1000,  # Very long invalid query
        "category": "education",
        "subcategory": "education.courses",
        "expected_status": 200,  # Should still return 200, but with error info
    },
]


def run_test(base_url: str, test_case: Dict[str, Any], use_mock: bool = False) -> bool:
    """Run a single test case against the API.

    Args:
        base_url: Base URL of the API.
        test_case: Test case dictionary with parameters.
        use_mock: Whether to use mock data.

    Returns:
        bool: True if test passed, False otherwise.
    """
    endpoint = f"{base_url}/niche-scout"
    params = {}

    if test_case["query"] is not None:
        params["query"] = test_case["query"]
    if test_case["category"] is not None:
        params["category"] = test_case["category"]
    if test_case["subcategory"] is not None:
        params["subcategory"] = test_case["subcategory"]

    # Add mock data parameter if requested
    if use_mock:
        params["use_mock"] = "true"

    print(f"\n=== Testing: {test_case['name']} ===")
    print(f"Endpoint: {endpoint}")
    print(f"Parameters: {params}")

    try:
        # Make the API request
        start_time = time.time()
        response = requests.post(endpoint, params=params, timeout=60)
        duration = time.time() - start_time

        # Check status code
        status_passed = response.status_code == test_case["expected_status"]

        # Try to parse response
        try:
            data = response.json()
            has_data = True
        except json.JSONDecodeError:
            data = None
            has_data = False

        # Print results
        print(f"Status: {response.status_code} (Expected: {test_case['expected_status']})")
        print(f"Response time: {duration:.2f} seconds")
        print(f"Response has valid JSON: {has_data}")

        if has_data:
            # Check if we got niches data
            niches = data.get("niches", [])
            print(f"Number of niches: {len(niches)}")

            # If we have at least one niche, print some details
            if niches:
                print(f"Top niche: {niches[0].get('name', 'Unknown')}")
                print(f"Growth rate: {niches[0].get('growth_rate', 'N/A')}")

            # Check for error indicators
            if "_mock" in data:
                print(f"Mock data used: {data['_mock']}")
            if "_error" in data:
                print(f"Error: {data['_error']}")

            # Save response to file for inspection
            # Create filename for test results
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            test_name = test_case["name"].replace(" ", "_").lower()
            filename = f"niche_scout_test_{test_name}_{timestamp}.json"
            with open(filename, "w") as f:
                json.dump(data, f, indent=2)
            print(f"Response saved to: {filename}")

        return status_passed and has_data

    except requests.RequestException as e:
        print(f"Request failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Test the Niche-Scout API")
    parser.add_argument(
        "--base-url",
        default="http://localhost:9000",
        help="Base URL of the Social Intelligence Service",
    )
    parser.add_argument("--mock", action="store_true", help="Use mock data")

    args = parser.parse_args()

    print(f"Testing Niche-Scout API at {args.base_url}")
    print(f"Using mock data: {args.mock}")

    results = []
    for test_case in TEST_CASES:
        result = run_test(args.base_url, test_case, args.mock)
        results.append(result)

    # Calculate test summary
    total = len(results)
    passed = sum(results)

    print("\n=== Test Summary ===")
    print(f"Total tests: {total}")
    print(f"Passed: {passed}")
    print(f"Failed: {total - passed}")
    print(f"Pass rate: {passed/total*100:.1f}%")

    # Exit with appropriate status code
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
