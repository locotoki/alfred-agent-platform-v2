#!/usr/bin/env python3
"""
Fix FastAPI route issues with response models.

This script addresses the "Invalid args for response field" errors by adding response_model=None
to the FastAPI route decorators in both financial-tax and legal-compliance services.
"""

import os
import sys
import subprocess
import re

# Define service paths
FINANCIAL_SERVICE_PATH = "/services/financial-tax/app/main.py"
LEGAL_SERVICE_PATH = "/services/legal-compliance/app/main.py"

def get_project_root():
    """Get the project root directory."""
    # This assumes the script is run from the project root or a subdirectory
    # Try to find the project root by looking for specific project files
    current_dir = os.getcwd()
    
    # Check if we're already at the project root
    if os.path.exists(os.path.join(current_dir, "docker-compose.yml")) and \
       os.path.exists(os.path.join(current_dir, "services")):
        return current_dir
    
    # If not, try to find it by checking for docker-compose.yml
    while current_dir != "/":
        if os.path.exists(os.path.join(current_dir, "docker-compose.yml")) and \
           os.path.exists(os.path.join(current_dir, "services")):
            return current_dir
        current_dir = os.path.dirname(current_dir)
    
    # If we can't find it, use the current directory as a fallback
    print("Warning: Could not locate project root. Using current directory.")
    return os.getcwd()

def fix_financial_service():
    """Fix FastAPI route issues in the financial-tax service."""
    project_root = get_project_root()
    service_path = os.path.join(project_root, FINANCIAL_SERVICE_PATH.lstrip('/'))
    
    if not os.path.exists(service_path):
        print(f"Error: Financial service file not found at {service_path}")
        return False
    
    print(f"Fixing FastAPI routes in financial-tax service at {service_path}")
    
    # Create a backup of the original file
    backup_path = f"{service_path}.bak"
    try:
        with open(service_path, 'r') as f:
            original_content = f.read()
        
        with open(backup_path, 'w') as f:
            f.write(original_content)
        
        print(f"Created backup at {backup_path}")
    except Exception as e:
        print(f"Error creating backup: {str(e)}")
        return False
    
    # Fix the route decorators to add response_model=None
    fixed_content = re.sub(
        r'(@app\.post\([^)]+\))',
        r'\1, response_model=None',
        original_content
    )
    
    # Also fix the GET endpoint
    fixed_content = re.sub(
        r'(@app\.get\("/api/v1/financial-tax/tax-rates/\{jurisdiction\}"\))',
        r'\1, response_model=None',
        fixed_content
    )
    
    # Also fix the task status endpoint
    fixed_content = re.sub(
        r'(@app\.get\("/api/v1/financial-tax/task/\{task_id\}"\))',
        r'\1, response_model=None',
        fixed_content
    )
    
    try:
        with open(service_path, 'w') as f:
            f.write(fixed_content)
        print("Financial service routes fixed successfully.")
        return True
    except Exception as e:
        print(f"Error writing fixed content: {str(e)}")
        return False

def fix_legal_service():
    """Fix FastAPI route issues in the legal-compliance service."""
    project_root = get_project_root()
    service_path = os.path.join(project_root, LEGAL_SERVICE_PATH.lstrip('/'))
    
    if not os.path.exists(service_path):
        print(f"Error: Legal service file not found at {service_path}")
        return False
    
    print(f"Fixing FastAPI routes in legal-compliance service at {service_path}")
    
    # Create a backup of the original file
    backup_path = f"{service_path}.bak"
    try:
        with open(service_path, 'r') as f:
            original_content = f.read()
        
        with open(backup_path, 'w') as f:
            f.write(original_content)
        
        print(f"Created backup at {backup_path}")
    except Exception as e:
        print(f"Error creating backup: {str(e)}")
        return False
    
    # Fix the route decorators to add response_model=None
    fixed_content = re.sub(
        r'(@app\.post\([^)]+\))',
        r'\1, response_model=None',
        original_content
    )
    
    # Also fix the task status endpoint
    fixed_content = re.sub(
        r'(@app\.get\("/api/v1/legal-compliance/task/\{task_id\}"\))',
        r'\1, response_model=None',
        fixed_content
    )
    
    try:
        with open(service_path, 'w') as f:
            f.write(fixed_content)
        print("Legal service routes fixed successfully.")
        return True
    except Exception as e:
        print(f"Error writing fixed content: {str(e)}")
        return False

def fix_container_files():
    """Fix FastAPI routes in running containers."""
    try:
        # Fix financial service container
        financial_result = subprocess.run(
            ["docker", "exec", "agent-financial", "python", "-c", """
import re

service_path = '/app/app/main.py'
try:
    with open(service_path, 'r') as f:
        original_content = f.read()
    
    # Create backup
    with open(service_path + '.bak', 'w') as f:
        f.write(original_content)
    
    # Fix route decorators
    fixed_content = re.sub(
        r'(@app\\.post\\([^)]+\\))',
        r'\\1, response_model=None',
        original_content
    )
    
    # Fix GET endpoints
    fixed_content = re.sub(
        r'(@app\\.get\\("/api/v1/financial-tax/tax-rates/\\{jurisdiction\\}"\\))',
        r'\\1, response_model=None',
        fixed_content
    )
    
    fixed_content = re.sub(
        r'(@app\\.get\\("/api/v1/financial-tax/task/\\{task_id\\}"\\))',
        r'\\1, response_model=None',
        fixed_content
    )
    
    with open(service_path, 'w') as f:
        f.write(fixed_content)
    
    print("Financial service container routes fixed successfully")
except Exception as e:
    print(f"Error fixing financial service container: {str(e)}")
            """],
            capture_output=True,
            text=True
        )
        
        print(financial_result.stdout)
        if financial_result.stderr:
            print(f"Error: {financial_result.stderr}")
        
        # Fix legal service container
        legal_result = subprocess.run(
            ["docker", "exec", "agent-legal", "python", "-c", """
import re

service_path = '/app/app/main.py'
try:
    with open(service_path, 'r') as f:
        original_content = f.read()
    
    # Create backup
    with open(service_path + '.bak', 'w') as f:
        f.write(original_content)
    
    # Fix route decorators
    fixed_content = re.sub(
        r'(@app\\.post\\([^)]+\\))',
        r'\\1, response_model=None',
        original_content
    )
    
    # Fix GET endpoints
    fixed_content = re.sub(
        r'(@app\\.get\\("/api/v1/legal-compliance/task/\\{task_id\\}"\\))',
        r'\\1, response_model=None',
        fixed_content
    )
    
    with open(service_path, 'w') as f:
        f.write(fixed_content)
    
    print("Legal service container routes fixed successfully")
except Exception as e:
    print(f"Error fixing legal service container: {str(e)}")
            """],
            capture_output=True,
            text=True
        )
        
        print(legal_result.stdout)
        if legal_result.stderr:
            print(f"Error: {legal_result.stderr}")
        
        return True
    except Exception as e:
        print(f"Error fixing container files: {str(e)}")
        return False

def main():
    """Main function to fix FastAPI route issues."""
    print("Starting to fix FastAPI route issues...")
    
    # Fix files in the project
    financial_fixed = fix_financial_service()
    legal_fixed = fix_legal_service()
    
    # Fix files in running containers
    container_fixed = fix_container_files()
    
    if financial_fixed and legal_fixed:
        print("\nLocal service files fixed successfully.")
    else:
        print("\nWarning: Some local service files could not be fixed.")
    
    if container_fixed:
        print("Container service files fixed successfully.")
    else:
        print("Warning: Container service files could not be fixed.")
    
    print("\nTo apply the changes, rebuild and restart the services:")
    print("  docker-compose down agent-financial agent-legal")
    print("  docker-compose up -d agent-financial agent-legal")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())