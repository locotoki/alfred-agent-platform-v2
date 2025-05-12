#!/usr/bin/env python3
"""
Script to identify documentation gaps for the current project phase (Financial-Tax Agent).
This will scan documentation files and identify missing or incomplete documentation based
on the requirements specified in the documentation roadmap.
"""

import os
import re
import json
from pathlib import Path

# Configure base directory
BASE_DIR = "/home/locotoki/projects/alfred-agent-platform-v2/docs"
OUTPUT_FILE = "/home/locotoki/projects/alfred-agent-platform-v2/doc-gaps-report.md"

# Required documentation for Financial-Tax Agent (Phase 6)
REQUIRED_DOCS = {
    "agent-architecture": {
        "path": "agents/financial_tax",
        "patterns": ["architecture", "design", "overview"],
        "required": True,
        "description": "Design documentation and workflow diagrams for Financial-Tax Agent"
    },
    "core-financial-analysis": {
        "path": "agents/financial_tax",
        "patterns": ["financial-analysis", "core-analysis", "implementation"],
        "required": True,
        "description": "Implementation guide and usage examples for financial analysis functionality"
    },
    "tax-compliance-verification": {
        "path": "agents/financial_tax",
        "patterns": ["tax-compliance", "verification", "compliance"],
        "required": True,
        "description": "Verification process and compliance standards documentation"
    },
    "api-endpoints": {
        "path": "agents/financial_tax",
        "patterns": ["api", "endpoints", "interface"],
        "required": True,
        "description": "API reference and integration guide for Financial-Tax Agent"
    },
    "test-suite": {
        "path": "agents/financial_tax/tests",
        "patterns": ["test", "coverage", "testing"],
        "required": False,
        "description": "Test coverage and test implementation documentation"
    }
}

def check_doc_exists(relative_path, patterns):
    """Check if documentation containing any of the patterns exists in the given path."""
    full_path = os.path.join(BASE_DIR, relative_path)
    
    if not os.path.exists(full_path):
        return False, None
    
    for root, _, files in os.walk(full_path):
        for file in files:
            if file.endswith(".md"):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        content = f.read().lower()
                    
                    # Check if file contains any of the patterns
                    for pattern in patterns:
                        if pattern.lower() in content or pattern.lower() in file.lower():
                            return True, file_path
                except Exception:
                    # Skip files with reading errors
                    continue
    
    return False, None

def check_doc_completeness(file_path, doc_type):
    """Check if the document has all required sections."""
    if not file_path or not os.path.exists(file_path):
        return False, []
    
    required_sections = []
    
    # Define required sections based on document type
    if doc_type == "agent-architecture":
        required_sections = ["overview", "architecture", "workflow", "diagram"]
    elif doc_type == "core-financial-analysis":
        required_sections = ["implementation", "usage", "example"]
    elif doc_type == "tax-compliance-verification":
        required_sections = ["verification", "compliance", "standards"]
    elif doc_type == "api-endpoints":
        required_sections = ["api", "endpoint", "integration"]
    elif doc_type == "test-suite":
        required_sections = ["test", "coverage"]
    
    # Check if file contains all required sections
    missing_sections = []
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read().lower()
        
        for section in required_sections:
            if section.lower() not in content:
                missing_sections.append(section)
    except Exception:
        return False, required_sections
    
    return len(missing_sections) == 0, missing_sections

def generate_report():
    """Generate a report of documentation gaps."""
    gaps = []
    
    for doc_type, doc_info in REQUIRED_DOCS.items():
        exists, file_path = check_doc_exists(doc_info["path"], doc_info["patterns"])
        
        if not exists:
            gaps.append({
                "type": doc_type,
                "status": "missing",
                "description": doc_info["description"],
                "required": doc_info["required"],
                "path": doc_info["path"]
            })
        else:
            complete, missing_sections = check_doc_completeness(file_path, doc_type)
            if not complete:
                gaps.append({
                    "type": doc_type,
                    "status": "incomplete",
                    "description": doc_info["description"],
                    "required": doc_info["required"],
                    "path": os.path.relpath(file_path, BASE_DIR),
                    "missing_sections": missing_sections
                })
    
    # Write the report
    with open(OUTPUT_FILE, "w") as f:
        f.write("# Documentation Gaps Report for Financial-Tax Agent (Phase 6)\n\n")
        f.write("## Summary\n\n")
        
        critical_gaps = [gap for gap in gaps if gap["required"]]
        minor_gaps = [gap for gap in gaps if not gap["required"]]
        
        f.write(f"- **Critical Gaps**: {len(critical_gaps)} missing or incomplete required documents\n")
        f.write(f"- **Minor Gaps**: {len(minor_gaps)} missing or incomplete optional documents\n\n")
        
        if critical_gaps:
            f.write("## Critical Documentation Gaps\n\n")
            for gap in critical_gaps:
                f.write(f"### {gap['type']}\n\n")
                f.write(f"- **Status**: {gap['status']}\n")
                f.write(f"- **Description**: {gap['description']}\n")
                f.write(f"- **Expected Path**: {gap['path']}\n")
                
                if gap['status'] == 'incomplete':
                    f.write(f"- **Document Path**: {gap['path']}\n")
                    f.write("- **Missing Sections**:\n")
                    for section in gap['missing_sections']:
                        f.write(f"  - {section}\n")
                
                f.write("\n")
        
        if minor_gaps:
            f.write("## Minor Documentation Gaps\n\n")
            for gap in minor_gaps:
                f.write(f"### {gap['type']}\n\n")
                f.write(f"- **Status**: {gap['status']}\n")
                f.write(f"- **Description**: {gap['description']}\n")
                f.write(f"- **Expected Path**: {gap['path']}\n")
                
                if gap['status'] == 'incomplete':
                    f.write(f"- **Document Path**: {gap['path']}\n")
                    f.write("- **Missing Sections**:\n")
                    for section in gap['missing_sections']:
                        f.write(f"  - {section}\n")
                
                f.write("\n")
        
        f.write("## Recommendations\n\n")
        f.write("1. **Priority**: Address critical gaps first, focusing on API documentation and architecture design\n")
        f.write("2. **Templates**: Use the templates in `/docs/templates/` for creating missing documentation\n")
        f.write("3. **Reviews**: Ensure all new documentation undergoes technical review by subject matter experts\n")
        f.write("4. **Alignment**: Align documentation with the Financial-Tax Agent implementation milestones\n")
        f.write("5. **Cross-References**: Add proper cross-references to related documentation\n")

if __name__ == "__main__":
    print("Checking for documentation gaps...")
    generate_report()
    print(f"Report generated: {OUTPUT_FILE}")