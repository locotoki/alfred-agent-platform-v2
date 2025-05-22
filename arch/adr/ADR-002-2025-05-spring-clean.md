# ADR-002: Spring-Clean Initiative (May 2025)

## Status
**Status: COMPLETE 🎉**

Accepted

## Context

The Alfred Agent Platform repository has accumulated a significant amount of code, scripts, and documentation files over time, some of which are no longer actively used or maintained. This accumulation has led to:

1. Increased cognitive load for new developers trying to understand the codebase
2. Difficulty in maintaining and evolving the platform
3. Reduced performance in CI/CD pipelines that process unused files
4. Unnecessary complexity in deployment and operations

As we prepare for the Agent Consolidation & Naming Standard sprint, we need to identify and handle these unused components to streamline development.

## Decision

We will implement a Spring-Clean initiative with the following classification system:

1. **C-0: USED** - Files actively used in the current implementation that should be preserved
   - Core platform code
   - Active configuration
   - Current documentation
   - Working CI/CD scripts
   - Tests for active components

2. **C-1: ORPHAN** - Files that appear to be unused or obsolete but require verification
   - Backup files
   - Outdated documentation
   - Deprecated scripts
   - Legacy configuration
   - Dead code paths
   - Redundant test files

3. **C-2: ARCHIVE** - Files that have historical value but aren't actively used
   - Previous architectural designs
   - Implementation records
   - Milestone documentation

4. **C-3: REMOVE** - Files conclusively determined to be unnecessary
   - Temporary files
   - Duplicate content
   - Superseded code
   - Failed experiments

## Consequences

### Positive

- Reduced repository size and complexity
- Clearer development paths
- Faster CI/CD pipelines
- Easier onboarding for new team members
- Better aligned with the upcoming Agent Consolidation & Naming Standard

### Negative

- Some historical context might be lost if files are incorrectly classified
- Initial classification requires significant effort
- Potential short-term disruption to development workflows

## Implementation Plan

1. Create an inventory of all files in the repository
2. Classify each file as USED, ORPHAN, ARCHIVE, or REMOVE
3. Begin with classification of files as either USED or ORPHAN (C-0/C-1)
4. Refine ORPHAN classification into ARCHIVE or REMOVE (C-2/C-3)
5. Archive files with historical value in a dedicated archive directory
6. Remove unnecessary files

## Classification Guidelines

When classifying files:

- **USED**: Files referenced by active code paths, current documentation, or working CI/CD pipelines
- **ORPHAN**: Files not obviously in use but requiring further investigation
- **ARCHIVE**: Files with historical or reference value that should be preserved but not in the main codebase
- **REMOVE**: Files conclusively determined to be unnecessary and safe to delete

For the initial C-0/C-1 inventory pass, all files should be classified as either USED or ORPHAN.
