#!/usr/bin/env python3
"""
Fix FastAPI route decorator syntax issues.

This script corrects syntax errors in the FastAPI route decorators
where response_model=None was added incorrectly after a closing parenthesis.
"""

import os
import sys
import re


def fix_financial_service():
    """Fix FastAPI route decorator syntax in the financial-tax service."""
    service_path = '/home/locotoki/projects/alfred-agent-platform-v2/services/financial-tax/app/main.py'
    
    if not os.path.exists(service_path):
        print(f"Error: Financial service file not found at {service_path}")
        return False
    
    print(f"Fixing FastAPI route decorators in financial-tax service at {service_path}")
    
    # Create a backup of the original file
    backup_path = f"{service_path}.bak2"
    try:
        with open(service_path, 'r') as f:
            original_content = f.read()
        
        with open(backup_path, 'w') as f:
            f.write(original_content)
        
        print(f"Created backup at {backup_path}")
    except Exception as e:
        print(f"Error creating backup: {str(e)}")
        return False
    
    # Fix the route decorators with the incorrect syntax
    fixed_content = re.sub(
        r'@app\.(post|get)\(([^)]+)\),\s*response_model=None',
        r'@app.\1(\2, response_model=None)',
        original_content
    )
    
    try:
        with open(service_path, 'w') as f:
            f.write(fixed_content)
        print("Financial service route decorators fixed successfully.")
        return True
    except Exception as e:
        print(f"Error writing fixed content: {str(e)}")
        return False


def fix_legal_service():
    """Fix FastAPI route decorator syntax in the legal-compliance service."""
    service_path = '/home/locotoki/projects/alfred-agent-platform-v2/services/legal-compliance/app/main.py'
    
    if not os.path.exists(service_path):
        print(f"Error: Legal service file not found at {service_path}")
        return False
    
    print(f"Fixing FastAPI route decorators in legal-compliance service at {service_path}")
    
    # Create a backup of the original file
    backup_path = f"{service_path}.bak2"
    try:
        with open(service_path, 'r') as f:
            original_content = f.read()
        
        with open(backup_path, 'w') as f:
            f.write(original_content)
        
        print(f"Created backup at {backup_path}")
    except Exception as e:
        print(f"Error creating backup: {str(e)}")
        return False
    
    # Fix the route decorators with the incorrect syntax
    fixed_content = re.sub(
        r'@app\.(post|get)\(([^)]+)\),\s*response_model=None',
        r'@app.\1(\2, response_model=None)',
        original_content
    )
    
    try:
        with open(service_path, 'w') as f:
            f.write(fixed_content)
        print("Legal service route decorators fixed successfully.")
        return True
    except Exception as e:
        print(f"Error writing fixed content: {str(e)}")
        return False


def fix_container_files():
    """Fix FastAPI route decorators in running containers."""
    print("Skipping container fixes for now. Will fix local files first.")
    return True


def main():
    """Main function to fix FastAPI route decorator syntax issues."""
    print("Starting to fix FastAPI route decorator syntax issues...")
    
    # Fix files in the project
    financial_fixed = fix_financial_service()
    legal_fixed = fix_legal_service()
    
    if financial_fixed and legal_fixed:
        print("\nLocal service files fixed successfully.")
    else:
        print("\nWarning: Some local service files could not be fixed.")
    
    print("\nTo apply the changes, rebuild and restart the services:")
    print("  docker-compose down agent-financial agent-legal")
    print("  docker-compose up -d agent-financial agent-legal")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())