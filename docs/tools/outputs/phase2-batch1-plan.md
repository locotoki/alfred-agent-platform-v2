# Phase 2: Batch 1 Migration Plan

*Last Updated: 2025-05-10*
*Owner: Documentation Team*
*Status: Ready*

This document outlines the plan for the first batch of document migrations in Phase 2 (Core Documentation Migration). These documents represent the highest-priority items identified in the migration tracking document.

## Timeline

- **Start Date:** 2025-05-28
- **Completion Target:** 2025-06-04
- **Review Date:** 2025-06-05

## Batch 1 Documents

| Priority | Document | Source Location | Target Location | Assigned To | Dependencies |
|----------|----------|----------------|----------------|-------------|--------------|
| 1 | A2A Protocol | `/services/a2a/README.md` | `/docs/api/a2a-protocol.md` | API Team | None |
| 2 | System Architecture | Multiple sources | `/docs/architecture/system-architecture.md` | Architecture Team | None |
| 3 | Agent Core | 5 files | `/docs/architecture/agent-core.md` | Architecture Team | System Architecture |
| 4 | Infrastructure Overview | Multiple sources | `/docs/operations/infrastructure-overview.md` | Infrastructure Team | None |
| 5 | Social Intelligence Agent | 12 files | `/docs/agents/social-intelligence-agent.md` | Agent Team | A2A Protocol, Agent Core |

## Source Document Details

### A2A Protocol

**Source Files:**
- `/services/a2a/README.md` (primary source)
- `/docs/api/agent-protocol-v2.md` (additional details)
- `/docs/development/a2a-protocol-standards.md` (standards information)

**Consolidation Approach:**
- Use `/services/a2a/README.md` as the base document
- Incorporate implementation details from agent-protocol-v2.md
- Add standards information from a2a-protocol-standards.md
- Format according to API documentation template
- Add comprehensive examples for each message type

### System Architecture

**Source Files:**
- `/docs/architecture/system-design.md` (primary source)
- `/docs/PHASE2_HLD.md` (high-level design)
- `/docs/architecture/platform-architecture.md` (components description)
- `/home/locotoki/docs/AI Agent Platform v2– Technical Design Guide.md` (technical design)

**Consolidation Approach:**
- Use system-design.md as base document
- Incorporate high-level architecture diagrams from PHASE2_HLD.md
- Add component descriptions from platform-architecture.md
- Ensure alignment with the already-migrated Technical Design Guide

### Agent Core

**Source Files:**
- `/services/agent-core/README.md` (primary source)
- `/docs/development/agent-core.md` (development documentation)
- `/docs/architecture/agent-framework.md` (framework documentation)
- `/docs/SHARED_LIBRARIES.md` (library documentation)
- `/services/agent-core/ARCHITECTURE.md` (detailed architecture)

**Consolidation Approach:**
- Use agent-core/README.md as base document
- Incorporate framework details from agent-framework.md
- Add library documentation from SHARED_LIBRARIES.md
- Include architecture details from ARCHITECTURE.md
- Organize as a comprehensive architecture document

### Infrastructure Overview

**Source Files:**
- `/docs/INFRASTRUCTURE_STATUS.md` (primary source)
- `/docs/INFRASTRUCTURE_STATUS_UPDATED.md` (updated information)
- `/docs/operations/infrastructure.md` (operations documentation)
- `/docs/SERVICE_CONTAINERIZATION.md` (containerization details)

**Consolidation Approach:**
- Use INFRASTRUCTURE_STATUS_UPDATED.md as the base for current status
- Incorporate operational details from operations/infrastructure.md
- Add containerization information from SERVICE_CONTAINERIZATION.md
- Format as a comprehensive infrastructure document

### Social Intelligence Agent

**Source Files:**
- `/docs/agents/social-intelligence-agent.md` (primary - incomplete)
- `/docs/staging-area/Social_Intel/Social Intel Agent 1eab4fd21ff0802f84b5eeace69c091e.md` (main documentation)
- `/docs/staging-area/Social_Intel/Untitled 1eab4fd21ff080db8facf25931bd652e.md` (additional details)
- `/docs/staging-area/Social_Intel/Social Intel Agent Role for YouTube Content Creati 1eab4fd21ff0806887a6e5319ba6660d.md` (role definition)
- `/services/social-intelligence/README.md` (implementation details)
- Plus 8 additional files with scattered documentation

**Consolidation Approach:**
- Use agent template as the base document
- Organize per agent documentation template
- Pull technical details from service README
- Incorporate role information from role definition document
- Add workflow details from scattered documentation
- Ensure compliance with agent documentation standards

## Migration Steps

For each document:

1. **Preparation (Day 1)**
   - Review all source documents
   - Identify key information to preserve
   - Create consolidation plan
   - Identify stakeholders for review

2. **Content Development (Days 2-4)**
   - Create initial draft using the migration script
   - Apply appropriate template
   - Consolidate information from all sources
   - Ensure proper formatting and cross-references
   - Validate links and references

3. **Technical Review (Day 5)**
   - Submit for review by technical stakeholders
   - Address feedback
   - Verify technical accuracy
   - Ensure all key information is preserved

4. **Finalization (Days 6-7)**
   - Apply final formatting
   - Update cross-references
   - Run validation tools
   - Update status in tracking document
   - Commit final version

## Validation Process

Each migrated document will undergo the following validation steps:

1. **Automated Validation**
   - Run doc_validator.py to check for standards compliance
   - Run update_metadata.py to ensure proper metadata
   - Validate with GitHub Actions workflow

2. **Manual Validation**
   - Review by technical stakeholder
   - Review by documentation team member
   - Cross-reference check to ensure all information preserved
   - Navigation verification

## Dependencies and Risks

| Risk | Mitigation |
|------|------------|
| Incomplete source documentation | Coordinate with technical teams for missing information |
| Conflicting information in source documents | Document conflicts and seek technical clarification |
| Technical inaccuracies | Schedule additional review time with subject matter experts |
| Broken links or references | Validate all links and establish appropriate redirects |
| Complex consolidation requirements | Allow extra time for documents with many source files |

## Success Criteria

A document migration is considered successful when:

1. All relevant information from source documents is preserved
2. Document complies with documentation standards
3. Document passes automated validation checks
4. Document is approved by technical stakeholders
5. Document is properly cross-referenced
6. Source document locations are noted for future reference

## Post-Migration Steps

After each document is migrated:

1. Update the migration tracking document
2. Update the migration dashboard
3. Update relevant catalogs
4. Add to completed migrations list
5. Update cross-references in other documents
6. Consider whether source documents should be archived

## Ready for Migration

- [x] Source documents identified
- [x] Target locations confirmed
- [x] Templates available
- [x] Validation tools ready
- [x] Technical stakeholders identified
- [x] Timeline established

Migration of Batch 1 documents is ready to begin on 2025-05-28.
