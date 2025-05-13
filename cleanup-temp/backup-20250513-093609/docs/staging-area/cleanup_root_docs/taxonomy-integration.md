# Taxonomy Integration for Alfred Agent Platform v2

## Overview
This document describes how the taxonomy system has been integrated across both the Mission Control UI (port 3007) and the Social Intelligence Agent (port 8080) interfaces.

## Centralized Configuration
The taxonomy settings are now centralized in two key locations:

1. **Mission Control**: `services/mission-control/src/utils/shared-taxonomy.ts`
2. **Agent Orchestrator**: `services/agent-orchestrator/src/config/taxonomy.ts`

These files contain identical category and subcategory mappings to ensure consistency across both platforms.

## UI Implementation
The shared taxonomy is implemented in multiple UI components:

1. **Mission Control**: 
   - `src/pages/workflows/niche-scout/improved-index.tsx` - Uses the shared taxonomy for Niche-Scout workflow
   - `src/components/workflows/NicheTaxonomySelector.tsx` - Component for category selection

2. **Agent Orchestrator**: 
   - `src/components/wizards/niche-scout/StepOne.tsx` - Uses the shared taxonomy for Agent UI
   - `src/pages/TaxonomySettings.tsx` - Settings page for taxonomy management

## Usage
When selecting a category and subcategory in either interface (Mission Control or Social Intelligence Agent), the same values are used, ensuring consistent data and reporting.

## Category Structure

### Main Categories
- Education & Learning
- Entertainment
- Technology & Gaming
- Lifestyle & Health
- Business & Finance
- Arts & Creativity
- Travel & Adventure
- Sports & Fitness
- Kids & Family

Each category has a corresponding set of subcategories. See the configuration files for details.

## Maintaining Synchronization
When updating taxonomy categories:

1. Update the core configuration files in both systems:
   - `services/mission-control/src/utils/shared-taxonomy.ts`
   - `services/agent-orchestrator/src/config/taxonomy.ts`

2. Test the changes in both UIs:
   - Mission Control: http://localhost:3007/workflows/niche-scout
   - Social Intelligence Agent: http://localhost:8080/agents/agent-1
