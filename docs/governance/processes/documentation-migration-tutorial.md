# Documentation Migration Tutorial

**Last Updated:** 2025-05-10
**Owner:** Documentation Team
**Status:** Active

## Overview

This tutorial provides a step-by-step guide for migrating documentation from its current location to the new documentation structure. Following these guidelines will ensure consistency, quality, and proper organization of all documentation in the Alfred Agent Platform v2.

## Prerequisites

Before beginning the migration process, ensure you have:

1. Access to both the source and target documentation repositories
2. Python 3.7+ installed for running the migration and validation tools
3. Basic understanding of Markdown formatting
4. Familiarity with the [Documentation Standards](../../governance/standards/documentation-standards.md)
5. Git credentials configured for committing changes

## Step 1: Inventory Existing Documentation

The first step is to create an inventory of all existing documentation that needs migration.

### Using the Inventory Tool

```bash
# Navigate to the tools directory
cd /path/to/docs/tools

# Run the inventory tool on the source documentation directory
python doc_migration_inventory.py --root-dir /path/to/source/docs --output-format json
```

The tool will generate a JSON file containing:
- A list of all Markdown files with metadata
- Potential duplicates based on content and title similarity
- Recommendations for target locations in the new structure

### Manual Inventory (Alternative)

If you prefer a manual approach:

1. Create a spreadsheet with columns for:
   - File path
   - Document title
   - Last updated date
   - Document owner
   - Target location
   - Migration status

2. Systematically go through the source directories and catalog all documentation

## Step 2: Create a Migration Plan

Based on the inventory, create a migration plan:

1. Prioritize documents based on:
   - Usage frequency
   - Business criticality
   - Documentation age (newer documents may need less reformatting)

2. Group documents by target category:
   - Agent documentation
   - Workflow documentation
   - Project documentation
   - Architecture documentation
   - Process documentation

3. Identify any documents that require special handling:
   - Documents with complex formatting
   - Documents with extensive links to other content
   - Documents with embedded diagrams or media

## Step 3: Prepare the Target Structure

Before migrating content, ensure the target directory structure exists:

```bash
# Create the required directory structure
mkdir -p docs/agents/{core,business,domain,personal,saas}
mkdir -p docs/workflows/by-agent docs/workflows/by-project
mkdir -p docs/projects
mkdir -p docs/architecture
mkdir -p docs/governance/{standards,processes}
mkdir -p docs/guides
```

## Step 4: Document Reformatting Process

For each document being migrated, follow these steps:

### Example: Migrating an Agent Document

**Original document (`old-docs/social-intelligence-agent-info.md`):**

```markdown
# Social Intelligence Agent

This document describes the Social Intelligence Agent.

## Features
- YouTube content analysis
- Market trend detection

## API
The API endpoints are...
```

**Reformatted document (`docs/agents/domain/social-intelligence.md`):**

```markdown
# Social Intelligence Agent

**Last Updated:** 2025-05-10
**Owner:** AI Research Team
**Status:** Active

## Overview

The Social Intelligence Agent analyzes social media content and market trends to provide insights for content strategy.

## Capabilities

- YouTube content analysis
- Market trend detection
- Competitor analysis
- Audience sentiment tracking

## Workflows

The Social Intelligence Agent supports the following workflows:

- [Niche Scout](../../workflows/by-agent/social-intel/niche-scout.md)
- [Trend Analysis](../../workflows/by-agent/social-intel/trend-analysis.md)

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_key` | string | none | YouTube API key |
| `analysis_depth` | string | "standard" | Analysis depth ("basic", "standard", "deep") |

## Example Usage

```python
from agents.social_intel import SocialIntelligenceAgent

agent = SocialIntelligenceAgent(api_key="your-api-key")
results = agent.analyze_niche("artificial intelligence")
```

## Related Documentation

- [YouTube API Configuration](../../workflows/youtube-api-configuration.md)
- [Content Factory Project](../../projects/content-factory/README.md)
```

### Key Reformatting Steps

1. **Add Required Metadata**
   - Title as level 1 heading
   - Last Updated date in YYYY-MM-DD format
   - Owner information
   - Status

2. **Follow Standard Document Structure**
   - Overview section providing a concise introduction
   - Proper heading hierarchy (no skipped levels)
   - Standardized sections based on document type

3. **Update Links**
   - Convert absolute to relative links
   - Update links to point to new document locations
   - Ensure all links use descriptive text

4. **Ensure Proper Formatting**
   - Specify language for all code blocks
   - Use tables for structured data
   - Apply consistent text formatting (bold/italic)

## Step 5: Migrating Documents

Once you've reformatted a document, follow these steps to migrate it:

1. **Save the Document to the Target Location**
   ```bash
   # Example: Migrating a social intelligence agent document
   cp reformatted-social-intelligence.md docs/agents/domain/social-intelligence.md
   ```

2. **Validate the Document**
   ```bash
   # Validate a single document
   python docs/tools/doc_validator.py --single-file docs/agents/domain/social-intelligence.md
   ```

3. **Fix Any Validation Issues**
   - Address errors and warnings identified by the validator
   - Re-run validation until the document passes

4. **Commit the Changes**
   ```bash
   git add docs/agents/domain/social-intelligence.md
   git commit -m "Migrate Social Intelligence Agent documentation"
   ```

## Step 6: Handling Duplicate Content

When you encounter duplicate content:

### Identifying Duplicates

The inventory tool will flag potential duplicates, but also:

1. Compare document titles and content manually
2. Check for slight variations of the same information
3. Identify documents that cover the same topic from different angles

### Resolving Duplicates

1. **Consolidation**: Merge multiple documents into a single comprehensive resource
   ```markdown
   # Market Analysis Workflow

   **Note:** This document consolidates information previously found in "Market Research Process",
   "Market Analysis Guide", and "Trend Research Workflow".
   ```

2. **Refactoring**: Break up large documents with mixed concerns
   ```markdown
   # YouTube Analysis

   For implementation details, see [YouTube API Integration](../api/youtube-integration.md).
   For usage workflows, see [Content Analysis Workflow](../workflows/content-analysis.md).
   ```

3. **Documentation Pointers**: Create redirections
   ```markdown
   # Market Research Process

   This document has been migrated to [Market Analysis Workflow](../workflows/market-analysis.md).
   ```

## Step 7: Using the Validation Tools

The documentation validation tool helps enforce standards across all migrated content.

### Running a Full Validation

```bash
# Validate all documents in the docs directory
python docs/tools/doc_validator.py /path/to/docs
```

### Understanding the Validation Report

The validation report includes:
- Overall compliance statistics
- Issues categorized by severity
- Suggested fixes for common problems

### Common Validation Issues

| Issue | Resolution |
|-------|------------|
| Missing metadata | Add the required metadata fields |
| Broken links | Update or remove invalid links |
| Skipped heading levels | Fix heading hierarchy |
| Missing language in code blocks | Add language specifier to code blocks |

## Step 8: Maintaining a Migration Tracker

Keep track of migration progress using a migration tracker document or spreadsheet:

```markdown
# Documentation Migration Tracker

| Document | Source Location | Target Location | Status | Issues | Assigned To |
|----------|----------------|----------------|--------|--------|-------------|
| Social Intelligence | old-docs/agents/ | docs/agents/domain/ | Complete | None | @username |
| Market Analysis | old-docs/processes/ | docs/workflows/ | In Progress | Link updates needed | @username |
```

## Best Practices

### Document Formatting

1. **Be Consistent**: Follow the same conventions throughout all documents
2. **Use Templates**: Start from the [standard templates](../../templates/) whenever possible
3. **Code Examples**: Always include working, tested code examples
4. **Links**: Use relative links to other documentation files

### Migration Process

1. **Migrate Related Documents Together**: Migrate groups of related documents at once
2. **Test Links**: After migrating a group of documents, verify all links work
3. **Incremental Commits**: Make small, focused commits rather than large batch changes
4. **Update References**: Check for any references to migrated documents in code/other docs

### Quality Assurance

1. **Peer Reviews**: Have another team member review migrated documents
2. **Regular Validation**: Run the validation tool weekly on the entire documentation set
3. **User Testing**: Have users follow procedures in the new documentation to verify accuracy
4. **Keep History**: Maintain information about the original source of migrated content

## Migration Checklist

Use this checklist to ensure you've completed all steps for each document:

- [ ] Document identified in inventory
- [ ] Target location determined
- [ ] Document reformatted according to standards
- [ ] Required metadata added
- [ ] Links updated to point to new locations
- [ ] Duplicate content resolved
- [ ] Document validated successfully
- [ ] Document committed to repository
- [ ] Migration tracker updated
- [ ] Related documents cross-referenced
- [ ] Old document marked as migrated or removed

## Troubleshooting

### Validation Tool Issues

**Problem**: Validation tool reports broken links for valid files
**Solution**: Check for case sensitivity issues or incorrect path separators

**Problem**: Validation fails with encoding errors
**Solution**: Ensure all files use UTF-8 encoding

### Migration Challenges

**Problem**: Document contains complex tables or formatting
**Solution**: Simplify tables or convert to more maintainable formats

**Problem**: External links are broken
**Solution**: Check if external resources have moved and update accordingly

**Problem**: Documents have circular references
**Solution**: Refactor document structure to create a clear hierarchy

## Conclusion

Following this tutorial will help ensure a smooth transition to the new documentation structure. By maintaining high standards and consistency throughout the migration process, we'll create a more usable, maintainable documentation system that better serves the needs of the Alfred Agent Platform v2 users and developers.

For additional assistance, contact the documentation team at docs@alfred-platform.example.com.

## Related Documentation

- [Documentation Standards](../../governance/standards/documentation-standards.md)
- [Documentation Process Guide](../../governance/processes/documentation-process.md)
- [Agent Template](../../templates/agent-template.md)
- [Workflow Template](../../templates/workflow-template.md)
- [Project Template](../../templates/project-template.md)
