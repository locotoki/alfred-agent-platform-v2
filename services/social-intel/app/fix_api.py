#!/usr/bin/env python3
"""
Fix script for social-intel API to handle JSON payloads properly.
This script updates the main.py file to add JSON body handling to the endpoints.
"""

import os
import re
import sys

# Define the file path
MAIN_PY_PATH = "/app/main.py"


def modify_endpoint(content, endpoint_pattern, new_param_pattern):
    """Modify an endpoint definition to handle JSON payloads."""
    # Find the endpoint
    matches = re.finditer(endpoint_pattern, content)
    for match in matches:
        endpoint_pos = match.start()

        # Find the parameter list closing parenthesis
        params_end_pattern = r'\):\s*"""'
        params_match = re.search(params_end_pattern, content[endpoint_pos:])
        if params_match:
            # Insert the request parameter
            insert_pos = endpoint_pos + params_match.start()
            content = content[:insert_pos] + new_param_pattern + content[insert_pos:]

    return content


def fix_json_handling(content):
    """Add JSON body handling to all endpoints."""
    # Add the Request import if not present
    if "from fastapi import FastAPI, HTTPException, Query" in content:
        content = content.replace(
            "from fastapi import FastAPI, HTTPException, Query",
            "from fastapi import FastAPI, HTTPException, Query, Request",
        )

    # Pattern to add request handling to niche-scout endpoint
    endpoint_pattern = r'@app\.post\("/niche-scout"\)\s*async def run_niche_scout\('
    new_param_pattern = "request: Request, "
    content = modify_endpoint(content, endpoint_pattern, new_param_pattern)

    # Pattern to add request handling to youtube/niche-scout endpoint
    endpoint_pattern = r'@app\.post\("/youtube/niche-scout"\)\s*async def run_niche_scout_alt1\('
    content = modify_endpoint(content, endpoint_pattern, new_param_pattern)

    # Pattern to add request handling to api/youtube/niche-scout endpoint
    endpoint_pattern = (
        r'@app\.post\("/api/youtube/niche-scout"\)\s*async def run_niche_scout_alt2\('
    )
    content = modify_endpoint(content, endpoint_pattern, new_param_pattern)

    # Update the call signature in the alternative endpoints
    content = content.replace(
        "return await run_niche_scout(query, category, subcategory)",
        "return await run_niche_scout(request, query, category, subcategory)",
    )

    # Find the run_niche_scout function implementation
    niche_scout_pattern = r'async def run_niche_scout\([^)]*\):\s*"""[^"]*"""'
    niche_scout_match = re.search(niche_scout_pattern, content)
    if niche_scout_match:
        # Insert JSON handling code
        implementation_pos = niche_scout_match.end()
        json_handling_code = """
    try:
        # Try to parse JSON body if present
        json_data = {}
        try:
            # Parse JSON
            json_data = await request.json()
            
            # Process the A2A envelope
            if json_data.get("intent") == "YOUTUBE_NICHE_SCOUT":
                data = json_data.get("data", {})
                
                # Get queries
                queries = data.get("queries", [])
                if queries and isinstance(queries, list):
                    query = queries[0]  # Use the first query
                
                # Get category
                json_category = data.get("category")
                if json_category:
                    if json_category != "All":
                        category = json_category
                    else:
                        category = None  # "All" means no category filtering
                        
                # Get subcategory if present
                if data.get("subcategory"):
                    subcategory = data.get("subcategory")
                    
        except Exception as e:
            # Just log the error and continue with query parameters
            logger.error("Failed to parse JSON body", error=str(e))
            
        # Always log the actual parameters used
        logger.info("niche_scout_request", 
                  query=query,
                  category=category,
                  subcategory=subcategory,
                  json_task_id=json_data.get("task_id", "none") if json_data else "none")
"""
        content = content[:implementation_pos] + json_handling_code + content[implementation_pos:]

    return content


def main():
    """Main function to fix the API."""
    print("Starting API fix script...")

    # Check if the file exists
    if not os.path.exists(MAIN_PY_PATH):
        print(f"Error: {MAIN_PY_PATH} not found!")
        sys.exit(1)

    # Read the file
    with open(MAIN_PY_PATH, "r") as f:
        content = f.read()

    # Modify the content
    new_content = fix_json_handling(content)

    # Write back to file
    with open(MAIN_PY_PATH, "w") as f:
        f.write(new_content)

    print("API fix complete! Restart the service to apply changes.")


if __name__ == "__main__":
    main()
