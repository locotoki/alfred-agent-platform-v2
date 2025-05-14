# Document Consolidation Plan

## Overview

This plan outlines the process for consolidating the documents that have been normalized in the staging area into the main documentation structure. The consolidation will follow the guidelines in the [Document Consolidation Guide](/home/locotoki/projects/alfred-agent-platform-v2/docs/governance/processes/document-consolidation-guide.md).

## Consolidation Groups

Based on the inventory analysis, the following consolidation groups have been identified:

### 1. RAG Service Documentation

Target location: `/docs/projects/rag-service/`

Files to consolidate:
- `rag-service.md` - Primary document
- `rag-service-architectural-rfc.md`
- `rag-service-json-schemas-v1.md`
- `rag-service-supplementary-toolkit.md`
- `rag-service-add-on-artifacts.md`
- `rag-service-client-packaging-codegen-guide.md`
- Other RAG service files

### 2. Infrastructure Crew Documentation

Target location: `/docs/infrastructure-crew/`

Files to consolidate:
- `infrastructure-crew.md` - Primary document
- `infra-architect-role-definition.md`
- `ai-agent-framework-guide-05072025.md`
- `infrastructure-architect-agent.md`
- Other infrastructure crew files

### 3. AI Agent Platform Documentation

Target location: `/docs/project/`

Files to consolidate:
- `ai-agent-platform-v2-master-project-plan.md` → `/docs/project/master-plan.md`
- `ai-agent-platform-v2-technical-design-guide.md` → `/docs/project/technical-design.md`
- Other AI Agent Platform files

### 4. Social Intelligence Documentation

Target location: `/docs/agents/social-intelligence-agent.md`

Files to consolidate:
- `social-intel-agent.md` - Primary document
- Social intelligence workflows
- YouTube workflow documentation

### 5. Alfred AI Assistant Documentation

Target location: `/docs/alfred_assistant_implementation/`

Files to consolidate:
- Alfred Home and Biz documentation

## Consolidation Process

For each group, the following process will be followed:

1. **Analyze Content Overlap**
   - Identify unique content in each document
   - Determine primary document to serve as the base

2. **Create Consolidated Structure**
   - Outline the consolidated document structure
   - Plan placement of unique content

3. **Execute Consolidation**
   - Create consolidated document based on primary document
   - Merge unique content from other documents
   - Ensure consistent formatting and style

4. **Update References**
   - Create redirects from original locations
   - Update internal links

5. **Validate Consolidation**
   - Check for content completeness
   - Verify links and references

## Phase Implementation

The consolidation will be implemented in phases, aligning with the overall migration plan:

1. **Phase 2 (Current)**: Core Documentation Migration
   - RAG Service documentation
   - AI Agent Platform documentation

2. **Phase 3 (Next)**: Agent Documentation
   - Social Intelligence documentation
   - Other agent documentation

3. **Phase 4**: Workflow Documentation
   - YouTube workflow documentation
   - Integration workflows

## Execution Plan

1. Create consolidated documents in target locations
2. Validate the consolidated documents
3. Update the migration tracking document
4. Commit and push changes to GitHub

## Tracking

Progress will be tracked in the migration tracking document (`/docs/migration-tracking.md`). Each consolidated document will be added to the "Completed Migrations" section with appropriate metadata.