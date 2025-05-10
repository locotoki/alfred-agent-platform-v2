# Document Consolidation Guide

**Last Updated:** 2025-05-10  
**Owner:** Documentation Team  
**Status:** Active

## Overview

This guide provides detailed instructions for consolidating duplicate or fragmented documentation into a single source of truth. It complements the [Documentation Migration Tutorial](./documentation-migration-tutorial.md) and serves as a reference for teams working on reorganizing and streamlining documentation.

## Table of Contents

1. [Step-by-Step Consolidation Process](#step-by-step-consolidation-process)
2. [Identifying Authoritative Sources](#identifying-authoritative-sources)
3. [Preserving Valuable Information](#preserving-valuable-information)
4. [Archive vs. Consolidate Decision Tree](#archive-vs-consolidate-decision-tree)
5. [Consolidation Checklist](#consolidation-checklist)
6. [Handling Conflicting Information](#handling-conflicting-information)
7. [Before/After Examples](#beforeafter-examples)
8. [Migration Tools for Consolidation](#migration-tools-for-consolidation)
9. [Consolidation Decision Template](#consolidation-decision-template)

## Step-by-Step Consolidation Process

### 1. Discovery Phase

1. **Identify Related Documents**
   - Use the documentation inventory tool to locate documents with similar titles, content, or topics
   - Review document links and references to identify connected content
   - Group documents into consolidation candidates

   ```bash
   python docs/tools/doc_migration_inventory.py --similarity-threshold 0.7
   ```

2. **Analyze Content Overlap**
   - For each group, examine:
     - Topics covered in each document
     - Uniqueness of information
     - Currency of information
     - Level of detail

3. **Map Consolidation Targets**
   - Determine which document will serve as the primary target
   - Create a mapping table of source documents to target location

### 2. Planning Phase

1. **Create Content Structure**
   - Outline the structure of the consolidated document
   - Ensure logical organization of topics
   - Plan location for unique information from each source

2. **Document Dependencies**
   - Identify all documents that link to the sources
   - Plan updates for these references
   - Prepare redirect strategy for deprecated URLs

3. **Create Consolidation Plan**
   - Document which content moves where
   - Specify how conflicts will be resolved
   - Set timeline and verification steps
   - Use the [Consolidation Decision Template](#consolidation-decision-template)

### 3. Execution Phase

1. **Create Draft Consolidated Document**
   - Begin with most complete document
   - Merge in content from other sources
   - Ensure consistent structure and voice
   - Apply standard templates and formatting

2. **Resolve Conflicts**
   - Apply [conflict resolution strategies](#handling-conflicting-information)
   - Document resolution decisions
   - Consult subject matter experts when needed

3. **Update References**
   - Update all internal links to point to the new location
   - Create redirects from old documents (see [Redirection Strategy](#redirection-strategy))

4. **Validate Consolidated Document**
   - Use validation tools to check formatting and links
   - Review against original source content
   - Verify all unique information was preserved

### 4. Finalization Phase

1. **Peer Review**
   - Have subject matter experts review consolidated content
   - Check for technical accuracy and completeness
   - Validate proper attribution if needed

2. **Removal/Archiving**
   - Archive original documents following the process
   - Create redirects for commonly accessed URLs
   - Update documentation inventory

3. **Announcement**
   - Communicate consolidation to affected teams
   - Provide links to new documentation
   - Update references in related systems

## Identifying Authoritative Sources

Use these criteria to determine the most authoritative version when conflicting information exists:

### Primary Indicators

| Indicator | Evaluation Method |
|-----------|-------------------|
| **Recency** | Most recently updated documentation, based on last modified date and git history |
| **Authorship** | Documentation created by the responsible team or recognized subject matter expert |
| **Validation** | Content that has been verified with stakeholders or through testing |
| **Comprehensiveness** | Documents with greatest detail and context |
| **References** | Documents with proper citations to code, designs, or other artifacts |

### Secondary Indicators

| Indicator | Evaluation Method |
|-----------|-------------------|
| **Usage Statistics** | Analytics data showing which document is most frequently used |
| **Technical Accuracy** | Assessment of factual correctness by subject matter experts |
| **Alignment with Code** | How well the document matches current implementation |
| **Adherence to Standards** | Conformity with documentation standards |

### Resolution Process

1. Compare documents based on primary indicators
2. If not conclusive, evaluate secondary indicators
3. If still unclear, consult with:
   - Original document authors
   - Current feature/component owners
   - Documentation owner
   - Engineering leadership (as last resort)

## Preserving Valuable Information

Follow these strategies to ensure no unique information is lost:

### Content Preservation Strategies

1. **Structured Merging**
   - Create sections for each unique topic
   - Consolidate overlapping content
   - Preserve unique examples, use cases, context

2. **Content Enrichment**
   - Use newer documents for core information
   - Supplement with details from older documents
   - Incorporate unique troubleshooting guidance from all sources

3. **Feature-Based Organization**
   - Group information by feature rather than document origin
   - Create comprehensive feature documentation
   - Cross-reference related features

### Content Types to Preserve

| Content Type | Preservation Approach |
|--------------|------------------------|
| **Code Examples** | Retain all unique, working examples; update outdated syntax |
| **Edge Cases** | Preserve all documented edge cases and special scenarios |
| **Troubleshooting** | Keep all unique troubleshooting steps and solutions |
| **Configuration Options** | Consolidate into comprehensive tables with descriptions |
| **Background Context** | Retain relevant historical context and design rationale |
| **Visualizations** | Preserve all diagrams that provide unique perspective |

### Documentation Metadata

- Retain authorship information from original documents
- Document source material references
- Keep version applicability information
- Preserve changelog history

## Archive vs. Consolidate Decision Tree

Use this decision tree to determine whether to consolidate or archive documentation:

```
START
|
+-- Is the content still relevant to current product? 
|   |
|   +-- NO --> Is it needed for historical reference?
|   |           |
|   |           +-- YES --> ARCHIVE with clear deprecated notice
|   |           |
|   |           +-- NO --> REMOVE entirely
|   |
|   +-- YES --> Does similar content exist elsewhere?
|               |
|               +-- NO --> KEEP as standalone document
|               |
|               +-- YES --> Is there significant unique content?
|                           |
|                           +-- YES --> CONSOLIDATE
|                           |
|                           +-- NO --> Are there many references to this document?
|                                       |
|                                       +-- YES --> REDIRECT to better document
|                                       |
|                                       +-- NO --> REMOVE with references updated
```

### Archiving Guidelines

When archiving documents:

1. Move to an `/archived` folder organized by date
2. Add prominent header indicating deprecated status
3. Add reference to current documentation
4. Update document metadata to show archive date
5. Remove from search indexing but maintain access for reference

### Redirection Strategy

For consolidated or archived documents:

1. Create a simple markdown file at the old location
2. Include a prominent notice about document relocation
3. Provide direct link to new document location
4. Add a last-modified date to the redirect file
5. Consider HTTP-level redirects for web documentation

Example redirect file:
```markdown
# [Document Title] - MOVED

This document has been consolidated into [New Document Title](path/to/new/document.md) as of 2025-05-10.

Please update your bookmarks accordingly.
```

## Consolidation Checklist

Use this checklist to ensure no information is lost during consolidation:

### Pre-Consolidation

- [ ] All source documents identified and analyzed
- [ ] Content overlap and uniqueness assessed
- [ ] Primary consolidation target identified
- [ ] Structure for consolidated document designed
- [ ] Consolidation decision document created
- [ ] All document dependencies and references identified
- [ ] Subject matter experts notified and available for consultation

### During Consolidation

- [ ] All unique content sections transferred
- [ ] All unique examples preserved
- [ ] All unique troubleshooting steps retained
- [ ] Conflicts identified and resolved
- [ ] Consistent terminology applied
- [ ] Standard formatting and structure followed
- [ ] Attribution to original authors included if appropriate
- [ ] Internal links updated to new structure
- [ ] Documentation metadata updated

### Post-Consolidation

- [ ] Validation tools executed with no errors
- [ ] Technical review completed
- [ ] Editorial review completed
- [ ] All redirects created and tested
- [ ] Original documents archived according to policy
- [ ] Documentation inventory updated
- [ ] Stakeholders notified of changes
- [ ] Search indices updated
- [ ] Analytics tracking updated to new document

## Handling Conflicting Information

When source documents contain conflicting information, use these approaches:

### 1. Evidence-Based Resolution

1. **Code as Truth**
   - Examine the actual implementation in code
   - Document behavior based on code review
   - Include code references in documentation

2. **Testing-Based Verification**
   - Test contradictory claims
   - Document verified behavior
   - Include test results or methodology

3. **Expert Consultation**
   - Consult document authors or code owners
   - Document consensus or current understanding
   - Include attribution for resolution

### 2. Version-Based Resolution

1. **Version-Specific Documentation**
   - Clearly indicate which versions behave differently
   - Document all behaviors with version applicability
   - Structure as "Prior to version X" vs. "From version X"

2. **Feature Flag Awareness**
   - Document behavior differences based on configuration
   - Explain how feature flags affect behavior
   - Provide configuration guidance

### 3. Conflict Documentation

When conflicts cannot be fully resolved:

1. **Transparent Documentation**
   - Clearly document the conflicting views
   - Present the most likely correct information first
   - Explain the nature of the uncertainty

2. **Research Needed Section**
   - Create a clearly marked section for unresolved items
   - Document current knowledge and gaps
   - Create issues to research unresolved conflicts

### Conflict Resolution Template

When documenting a resolved conflict:

```markdown
> **Note on [feature/behavior]**: Previous documentation stated [conflicting information]. 
> This has been resolved by [method: code verification/testing/expert consultation] showing that 
> [correct behavior]. Reference: [link to code/test/discussion].
```

## Before/After Examples

### Example 1: Fragmented API Documentation

**Before Consolidation:**

Three separate documents with overlapping information:

1. `api-overview.md` - Brief overview of API endpoints
2. `api-authentication.md` - Authentication details and some endpoint descriptions
3. `api-examples.md` - Examples for some endpoints, with duplicated endpoint descriptions

**After Consolidation:**

A single comprehensive API document with logical sections:

```markdown
# API Documentation

## Overview
[Comprehensive overview from api-overview.md]

## Authentication
[Complete authentication details from api-authentication.md]

## Endpoints
[For each endpoint]
- Description (best from all sources)
- Parameters (consolidated from all sources)
- Response format (most detailed version)
- Examples (all unique examples preserved)
- Notes and edge cases (all preserved)

## Error Handling
[Consolidated from all sources]

## Best Practices
[Unique content from all sources]
```

### Example 2: Conflicting Configuration Options

**Before Consolidation:**

Two documents with conflicting information:

1. `setup-guide.md` - Lists configuration option `debug_level` with values "low", "medium", "high"
2. `advanced-config.md` - States `debug_level` takes numeric values 0-5

**After Consolidation:**

```markdown
## Configuration Options

| Option | Type | Values | Default | Description |
|--------|------|--------|---------|-------------|
| `debug_level` | string or integer | "low" (0), "medium" (3), "high" (5), or 0-5 integer | "low" | Controls verbosity of debug output |

> **Note**: This option accepts either string aliases ("low", "medium", "high") or direct numeric values (0-5). String aliases are mapped to specific numeric values: "low"=0, "medium"=3, "high"=5. Numeric values provide finer control over debug verbosity.
```

### Example 3: Workflow Documentation

**Before Consolidation:**

Three partial workflow documents:

1. `quick-start.md` - Basic workflow steps
2. `workflow-details.md` - Detailed explanation of some steps
3. `workflow-troubleshooting.md` - Troubleshooting for the workflow

**After Consolidation:**

```markdown
# Complete Workflow Guide

## Overview
[Comprehensive description]

## Quick Start
[Streamlined steps from quick-start.md]

## Detailed Process
[For each workflow step]
- Step description (from quick-start.md)
- Detailed explanation (from workflow-details.md)
- Configuration options (consolidated)
- Examples (all unique examples)

## Troubleshooting
[All unique troubleshooting items, organized by workflow step]

## Advanced Usage
[Unique advanced scenarios from all sources]
```

## Migration Tools for Consolidation

These tools from the migration toolkit can assist with consolidation:

### 1. Content Similarity Analyzer

```bash
python docs/tools/content_similarity.py --source-docs "path/to/doc1.md path/to/doc2.md" --output-format html
```

This tool:
- Compares multiple documents for similarity
- Highlights overlapping content
- Identifies unique sections in each document
- Provides recommendations for consolidation

### 2. Link Dependency Checker

```bash
python docs/tools/link_checker.py --doc path/to/doc.md --find-references
```

This tool:
- Identifies all documents that link to a given document
- Validates links within documents
- Helps plan reference updates during consolidation

### 3. Content Merger

```bash
python docs/tools/doc_merger.py --sources "doc1.md doc2.md doc3.md" --output consolidated.md --structure structure.json
```

This tool:
- Automatically merges content from multiple sources
- Follows a defined structure for the output
- Flags potential conflicts for manual resolution
- Preserves unique content from all sources

### 4. Redirect Generator

```bash
python docs/tools/create_redirects.py --source-target-map mapping.json
```

This tool:
- Creates redirect files based on a source-to-target mapping
- Updates references in other documents
- Generates reports of changed references

### 5. Consolidation Validator

```bash
python docs/tools/consolidation_validator.py --sources "doc1.md doc2.md" --result consolidated.md
```

This tool:
- Verifies all unique content from sources exists in the consolidated document
- Identifies potential information loss
- Validates formatting and structure
- Confirms all links have been properly updated

## Consolidation Decision Template

Use this template to document consolidation decisions:

```markdown
# Documentation Consolidation Decision

## Source Documents

| Document | Path | Last Updated | Owner | Status |
|----------|------|--------------|-------|--------|
| [Document 1 Title] | [path/to/doc1.md] | YYYY-MM-DD | [Owner] | [Active/Outdated] |
| [Document 2 Title] | [path/to/doc2.md] | YYYY-MM-DD | [Owner] | [Active/Outdated] |
| [Document 3 Title] | [path/to/doc3.md] | YYYY-MM-DD | [Owner] | [Active/Outdated] |

## Consolidation Target

- **Target Document:** [path/to/target.md]
- **Document Title:** [Consolidated Title]
- **Primary Owner:** [Owner]

## Content Analysis

### Overlap Assessment

[Describe overlap between documents, with percentages if possible]

### Unique Content Summary

| Source | Unique Content Areas |
|--------|----------------------|
| Doc 1 | [List unique sections/information] |
| Doc 2 | [List unique sections/information] |
| Doc 3 | [List unique sections/information] |

### Identified Conflicts

| Topic | Conflicting Information | Resolution Approach |
|-------|-------------------------|---------------------|
| [Topic 1] | [Describe conflict] | [Explain resolution] |
| [Topic 2] | [Describe conflict] | [Explain resolution] |

## Consolidation Structure

[Outline of the consolidated document structure]

## Dependencies

| Document | References To Update |
|----------|----------------------|
| [Doc A] | [List references to update] |
| [Doc B] | [List references to update] |

## Migration Plan

- **Scheduled Date:** YYYY-MM-DD
- **Responsible:** [Person responsible]
- **Reviewers:** [List reviewers]
- **Expected Completion:** YYYY-MM-DD

## Post-Migration

- [ ] Original documents archived at [location]
- [ ] Redirects created
- [ ] All references updated
- [ ] Stakeholders notified
- [ ] Validation completed
```

## Related Documentation

- [Documentation Migration Tutorial](./documentation-migration-tutorial.md)
- [Documentation Process Guide](./documentation-process.md)
- [Documentation Standards](../standards/documentation-standards.md)