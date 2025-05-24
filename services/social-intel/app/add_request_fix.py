#!/usr/bin/env python3
"""Simple script to add Request parameter to endpoint handlers"""

import re
import sys


def patch_endpoints(file_path):
    """Add Request parameter to endpoint handlers"""
    with open(file_path, "r") as f:
        content = f.read()

    # Add Request import
    content = re.sub(
        r"from fastapi import FastAPI, HTTPException, Query",
        "from fastapi import FastAPI, HTTPException, Query, Request",
        content,
    )

    # Add Request parameter to niche-scout endpoint
    content = re.sub(
        r'(@app\.post\("/niche-scout"\)\s*async def run_niche_scout\()',
        r"\1request: Request, ",
        content,
    )

    # Add Request parameter to youtube/niche-scout endpoint
    content = re.sub(
        r'(@app\.post\("/youtube/niche-scout"\)\s*async def run_niche_scout_alt1\()',
        r"\1request: Request, ",
        content,
    )

    # Add Request parameter to api/youtube/niche-scout endpoint
    content = re.sub(
        r'(@app\.post\("/api/youtube/niche-scout"\)\s*async def run_niche_scout_alt2\()',
        r"\1request: Request, ",
        content,
    )

    # Fix the function calls
    content = re.sub(
        r"return await run_niche_scout\(query, category, subcategory\)",
        r"return await run_niche_scout(request, query, category, subcategory)",
        content,
    )

    # Add JSON body handling to the niche-scout endpoint
    content = re.sub(
        r'"""Run the Niche-Scout workflow to find trending YouTube niches"""\s*try:',
        r'."""Run the Niche-Scout workflow to find trending YouTube niches"""\n    try:\n        # Try to parse JSON body if present\n        json_data = {}\n        try:\n            json_data = await requestjson()\n            \n            # Process the A2A envelope\n            if json_data.get("intent") == "YOUTUBE_NICHE_SCOUT":\n                data = json_data.get("data", {})\n                \n                # Get queries\n                queries = data.get("queries", [])\n                if queries and isinstance(queries, list):\n                    query = queries[0]  # Use the first query\n                \n                # Get category\n                json_category = data.get("category")\n                if json_category:\n                    if json_category != "All":\n                        category = json_category\n                    else:\n                        category = None  # "All" means no category filtering\n        except Exception as e:\n            # Log the error and continue with query parameters\n            pass\n        \n        # Log the final parameters being used\n        logger.info("niche_scout_request",\n                  query=query,\n                  category=category,\n                  subcategory=subcategory,\n                  has_json=bool(json_data))\n        try:',
        content,
    )

    # Write the updated content
    with open(file_path, "w") as f:
        f.write(content)

    print(f"Successfully patched {file_path}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python add_request_fix.py <file_path>")
        sys.exit(1)

    patch_endpoints(sys.argv[1])
