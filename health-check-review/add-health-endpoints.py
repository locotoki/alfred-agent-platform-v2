#!/usr/bin/env python3
"""
Script to add standardized health endpoints to FastAPI services.
This script adds a /health endpoint to services that only have /healthz.
"""
import os
import re
import glob
from pathlib import Path

def process_file(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Check if file has FastAPI and /healthz but no /health endpoint
    if 'fastapi' in content.lower() and '/healthz' in content and '/health' not in content:
        print(f"Processing {file_path}...")
        
        # Look for @app.get("/healthz") pattern
        healthz_pattern = r'@app\.get\(["\']\/healthz["\']\)'
        health_endpoint = '@app.get("/health")\nasync def health():\n    return {"status": "healthy"}\n\n'
        
        # Check if we already have a healthz function we can duplicate
        if re.search(healthz_pattern, content):
            # Extract the entire healthz function
            healthz_func_pattern = r'(@app\.get\(["\']\/healthz["\']\).*?def.*?\(.*?\).*?return.*?})'
            healthz_func_match = re.search(healthz_func_pattern, content, re.DOTALL)
            
            if healthz_func_match:
                healthz_func = healthz_func_match.group(1)
                # Create a health function based on the healthz function
                health_func = healthz_func.replace('/healthz', '/health')
                
                # Add the health function after the healthz function
                modified_content = content.replace(healthz_func, healthz_func + '\n\n' + health_func)
                
                with open(file_path, 'w') as f:
                    f.write(modified_content)
                
                print(f"Added /health endpoint to {file_path}")
                return True
        
        # If we couldn't find a healthz function to duplicate, add a simple health endpoint
        # Find the right place to add the endpoint
        if '@app.get' in content:
            # Add after the first @app.get
            modified_content = re.sub(
                r'(@app\.get\(.*?\).*?def.*?\(.*?\).*?})',
                r'\1\n\n' + health_endpoint,
                content,
                count=1,
                flags=re.DOTALL
            )
            
            with open(file_path, 'w') as f:
                f.write(modified_content)
            
            print(f"Added /health endpoint to {file_path}")
            return True
    
    return False

def scan_services():
    services_dir = '/home/locotoki/projects/alfred-agent-platform-v2/services'
    agents_dir = '/home/locotoki/projects/alfred-agent-platform-v2/agents'
    
    modified_files = []
    
    # Process main.py files in services directory
    for main_py in glob.glob(f"{services_dir}/**/main.py", recursive=True):
        if process_file(main_py):
            modified_files.append(main_py)
    
    # Process app.py files in services directory
    for app_py in glob.glob(f"{services_dir}/**/app.py", recursive=True):
        if process_file(app_py):
            modified_files.append(app_py)
            
    # Process server.py files in services directory
    for server_py in glob.glob(f"{services_dir}/**/server.py", recursive=True):
        if process_file(server_py):
            modified_files.append(server_py)
    
    # Process agent.py files in agents directory
    for agent_py in glob.glob(f"{agents_dir}/**/agent.py", recursive=True):
        if process_file(agent_py):
            modified_files.append(agent_py)
    
    return modified_files

if __name__ == "__main__":
    modified_files = scan_services()
    
    if modified_files:
        print("\nModified files:")
        for file in modified_files:
            print(f"- {file}")
        print("\nPlease verify the changes and rebuild affected services.")
    else:
        print("No files needed modifications.")