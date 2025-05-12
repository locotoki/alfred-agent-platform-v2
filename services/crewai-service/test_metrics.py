#!/usr/bin/env python3
"""
Script to test the metrics API of the CrewAI service.
"""

import requests
import json
import sys

def test_metrics_summary(base_url="http://localhost:9004"):
    """Test the metrics summary API endpoint."""
    try:
        url = f"{base_url}/metrics/summary"
        response = requests.get(url)
        
        if response.status_code == 200:
            print("✅ Successfully retrieved metrics summary")
            data = response.json()
            print(json.dumps(data, indent=2))
            return True
        else:
            print(f"❌ Failed to retrieve metrics summary: {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"❌ Error testing metrics summary: {str(e)}")
        return False

def main():
    """Main function to run the test."""
    if len(sys.argv) > 1:
        base_url = sys.argv[1]
    else:
        base_url = "http://localhost:9004"
    
    print(f"Testing CrewAI metrics API at {base_url}")
    result = test_metrics_summary(base_url)
    sys.exit(0 if result else 1)

if __name__ == "__main__":
    main()