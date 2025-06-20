# AI Prompt: Document Creation

Use this prompt when asking an AI tool to help create new documentation for the Alfred Agent Platform.

## Claude Desktop/Claude Code Prompt

```
You are a Documentation Expert for the Alfred Agent Platform. Your task is to help me create high-quality documentation following our established standards and templates.

I need to create a new [DOCUMENT_TYPE] document for [NAME]. This document will be stored at [FILE_PATH].

## Document Type Information

[Provide specific requirements for the document type - agent, workflow, or project]

## Template to Follow

[Paste the template content here or provide the path to the template file]

## Information About [NAME]

[Provide all relevant information about the agent, workflow, or project]

## Requirements

Please create a comprehensive, well-structured document following these guidelines:

1. Strictly follow the template structure provided
2. Use clear, concise language appropriate for technical documentation
3. Include all information provided, organizing it into the appropriate sections
4. Use proper Markdown formatting, including:
   - Consistent heading levels (# for title, ## for sections, ### for subsections)
   - Code blocks with language specifiers where appropriate
   - Tables for structured information
   - Bullet points for lists
   - Proper link formatting for cross-references
5. Ensure all relative links to other documentation use the format `../../path/to/document.md`
6. Where information is missing, include placeholders clearly marked as [TBD] or [PLACEHOLDER]
7. Include "Last Updated: [TODAY'S DATE]" at the top of the document

## Additional Instructions

- Be specific and precise
- Provide examples where helpful
- Ensure technical accuracy
- Maintain consistent formatting throughout

Please generate the complete document following these requirements.
```

## ChatGPT Prompt

```
I need your help creating comprehensive documentation for the Alfred Agent Platform. I'm creating a new [DOCUMENT_TYPE] document for [NAME] to be stored at [FILE_PATH].

Please follow our documentation standards:

1. Document Purpose: [Brief description of what this document is for]

2. Template Structure: The document should follow this template:
[Paste template here]

3. Available Information:
[All information you have about the subject]

4. Formatting Requirements:
- Use standard Markdown
- Consistent heading hierarchy
- Tables for structured data
- Code blocks with language specifiers
- Proper link formatting (../../path/to/document.md)

5. Key Sections to Focus On:
[List any sections requiring special attention]

Generate a complete, well-structured document following our template and incorporating all the information provided. Where information is missing, include clear [PLACEHOLDER] markers.
```

## Example: Creating Agent Documentation

```
You are a Documentation Expert for the Alfred Agent Platform. Your task is to help me create high-quality documentation following our established standards and templates.

I need to create a new AGENT document for Social Intelligence. This document will be stored at /docs/agents/domain/architect-apiligence.md.

## Document Type Information

This is a Domain-specific agent that focuses on social media trend analysis. The documentation should clearly explain its capabilities, workflows, and integration points.

## Template to Follow

# [Agent Name]

**Last Updated:** YYYY-MM-DD
**Owner:** [Owner Name/Team]
**Status:** [Planned/In Development/Active]

## Overview

[Provide a 2-3 paragraph description of the agent, its purpose, and its primary value proposition. Explain what problem this agent solves and for whom.]

## Agent Metadata

| Attribute | Value |
|-----------|-------|
| Category | [Core/Personal/Business/SaaS/Domain] |
| Primary Category | [If multi-category] |
| Secondary Categories | [If multi-category] |
| Tier | [System/Personal/Solo-Biz/SaaS] |
| Status | [Planned/In Development/Active] |
| Version | [Current version, e.g., 1.0.0] |

[... rest of template ...]

## Information About Social Intelligence Agent

- The Social Intelligence Agent analyzes social media trends to identify opportunities for content creators
- Primary capabilities include trend analysis, niche discovery, and content strategy generation
- Current version is 1.0.0 and it's in Active status
- It supports two main workflows: Niche-Scout and Seed-to-Blueprint
- Niche-Scout analyzes YouTube data to find trending niches with growth metrics
- Seed-to-Blueprint creates complete channel strategies from seed videos or keywords
- It integrates with YouTube Data API, Google Trends API, and internal analytics engines
- Input types include keywords, categories, time ranges, and demographic filters
- Output types include trend analysis, opportunity scores, and content recommendations
- The agent belongs to both Domain (primary) and Business (secondary) categories
- It operates at the Solo-Biz tier with potential expansion to SaaS tier

## Requirements

[... rest of the prompt ...]
```

## Tips for Effective Document Creation

1. **Be Specific About Document Type**: Clearly state whether you're creating agent, workflow, or project documentation.

2. **Provide the Full Template**: Always include the complete template for the AI to follow.

3. **Include All Available Information**: Give the AI as much information as possible about the subject.

4. **Specify Important Sections**: Highlight any sections that require special attention or detail.

5. **Review and Refine**: The AI's output should be reviewed and refined before being added to the documentation.

6. **Iterate if Necessary**: If the initial output isn't satisfactory, provide feedback and ask for specific improvements.
