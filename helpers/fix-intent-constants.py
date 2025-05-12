#!/usr/bin/env python3
"""
Helper script to patch agent intent constants within running containers.
"""

import os
import sys
import subprocess

FINANCIAL_INIT_PATH = "/app/agents/financial_tax/__init__.py"
LEGAL_INIT_PATH = "/app/agents/legal_compliance/__init__.py"

# Intent constants to be prepended to __init__.py files
FINANCIAL_CONSTANTS = """
# Intent constants
TAX_CALCULATION = "tax_calculation"
FINANCIAL_ANALYSIS = "financial_analysis"
TAX_COMPLIANCE_CHECK = "tax_compliance_check"
RATE_SHEET_LOOKUP = "rate_sheet_lookup"
"""

LEGAL_CONSTANTS = """
# Intent constants
COMPLIANCE_AUDIT = "compliance_audit"
DOCUMENT_ANALYSIS = "document_analysis"
REGULATION_CHECK = "regulation_check"
CONTRACT_REVIEW = "contract_review"
"""

def main():
    """
    Main function to patch the intent constants in agent __init__.py files.
    """
    # Fix financial agent
    print("Attempting to fix intent constants...")
    
    try:
        financial_result = subprocess.run(
            ["docker", "exec", "agent-financial", "python", "-c", 
             f'import shutil; f = open("{FINANCIAL_INIT_PATH}", "r"); '
             f'content = f.read(); f.close(); '
             f'if "TAX_CALCULATION =" not in content: '
             f'    backup = "{FINANCIAL_INIT_PATH}.bak"; '
             f'    shutil.copy("{FINANCIAL_INIT_PATH}", backup); '
             f'    with open("{FINANCIAL_INIT_PATH}", "w") as f: '
             f'        f.write("""{FINANCIAL_CONSTANTS}""" + content); '
             f'    print("Financial agent __init__.py patched successfully."); '
             f'else: '
             f'    print("Financial agent intent constants already defined.");'
            ],
            capture_output=True,
            text=True
        )
        
        print(financial_result.stdout)
        if financial_result.stderr:
            print("Error:", financial_result.stderr)
            
        legal_result = subprocess.run(
            ["docker", "exec", "agent-legal", "python", "-c", 
             f'import shutil; f = open("{LEGAL_INIT_PATH}", "r"); '
             f'content = f.read(); f.close(); '
             f'if "COMPLIANCE_AUDIT =" not in content: '
             f'    backup = "{LEGAL_INIT_PATH}.bak"; '
             f'    shutil.copy("{LEGAL_INIT_PATH}", backup); '
             f'    with open("{LEGAL_INIT_PATH}", "w") as f: '
             f'        f.write("""{LEGAL_CONSTANTS}""" + content); '
             f'    print("Legal agent __init__.py patched successfully."); '
             f'else: '
             f'    print("Legal agent intent constants already defined.");'
            ],
            capture_output=True,
            text=True
        )
        
        print(legal_result.stdout)
        if legal_result.stderr:
            print("Error:", legal_result.stderr)
            
        print("\nRestarting services...")
        restart_result = subprocess.run(
            ["docker-compose", "restart", "agent-financial", "agent-legal"],
            capture_output=True,
            text=True
        )
        
        print(restart_result.stdout)
        if restart_result.stderr:
            print("Warning:", restart_result.stderr)
            
        print("\nPatch complete. Wait 10-15 seconds for services to restart, then check health.")
        
    except Exception as e:
        print(f"An error occurred: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    sys.exit(main())