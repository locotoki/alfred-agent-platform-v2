#!/usr/bin/env python3
"""
Script to test submitting a task to the CrewAI service.
"""

import requests
import json
import sys
import time
import uuid

def submit_crew_task(crew_type="research", base_url="http://localhost:9004"):
    """Submit a test task to a crew."""
    try:
        task_id = f"test-{uuid.uuid4()}"
        url = f"{base_url}/crews/{crew_type}/tasks"
        
        payload = {
            "task_id": task_id,
            "tenant_id": "test",
            "content": {
                "objective": "Research the benefits of microservices architecture",
                "process_type": "sequential"
            }
        }
        
        response = requests.post(url, json=payload)
        
        if response.status_code == 200:
            print(f"✅ Successfully submitted task to {crew_type} crew")
            data = response.json()
            print(json.dumps(data, indent=2))
            print(f"Task ID: {task_id}")
            return task_id
        else:
            print(f"❌ Failed to submit task: {response.status_code}")
            print(response.text)
            return None
    except Exception as e:
        print(f"❌ Error submitting task: {str(e)}")
        return None

def check_task_status(task_id, base_url="http://localhost:9004"):
    """Check the status of a submitted task."""
    try:
        url = f"{base_url}/tasks/{task_id}"
        response = requests.get(url)
        
        if response.status_code == 200:
            print(f"✅ Successfully retrieved task status")
            data = response.json()
            print(json.dumps(data, indent=2))
            return data
        else:
            print(f"❌ Failed to get task status: {response.status_code}")
            print(response.text)
            return None
    except Exception as e:
        print(f"❌ Error checking task status: {str(e)}")
        return None

def main():
    """Main function to run the test."""
    if len(sys.argv) > 1:
        crew_type = sys.argv[1]
    else:
        crew_type = "research"
        
    if len(sys.argv) > 2:
        base_url = sys.argv[2]
    else:
        base_url = "http://localhost:9004"
    
    print(f"Testing CrewAI service at {base_url} with {crew_type} crew")
    task_id = submit_crew_task(crew_type, base_url)
    
    if task_id:
        print("Waiting 5 seconds before checking status...")
        time.sleep(5)
        check_task_status(task_id, base_url)

if __name__ == "__main__":
    main()