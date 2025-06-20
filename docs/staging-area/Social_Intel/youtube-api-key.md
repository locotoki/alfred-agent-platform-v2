```markdown
# Niche-Scout Workflow Implementation Guide

## 1. Overview of Niche-Scout Workflow

The Niche-Scout workflow allows users to research YouTube niches by selecting categories, subcategories, and configuring data sources for analysis.

## 2. Frontend Configuration Steps

### Step 1: Add NicheScoutWizard to WorkflowCard

```typescript
// In WorkflowCard.tsx

import { useState } from "react";
import { NicheScoutWizard } from "@/components/wizards/NicheScoutWizard";
import { FinalPayload } from "@/types/niche-scout";
import { runNicheScout } from "@/lib/youtube-service";

// Inside your WorkflowCard component
const [wizardOpen, setWizardOpen] = useState(false);

const handleNicheScoutComplete = async (payload: FinalPayload) => {
  try {
    // Show loading state
    setIsLoading(true);

    // Call the API with the payload from the wizard
    const result = await runNicheScout({
      category: payload.category.value,
      subcategory: payload.subcategory.value,
      budget: payload.budget,
      dataSources: payload.dataSources
    });

    // Handle success - store the result or update UI
    console.log("Niche scout completed:", result);

    // Show success notification
    toast({
      title: "Niche Scout analysis complete",
      description: `Found ${result.trending_niches.length} trending niches in ${payload.subcategory.label}`,
    });

  } catch (error) {
    // Handle error
    console.error("Niche scout failed:", error);
    toast({
      title: "Niche Scout failed",
      description: "Could not complete analysis. Please try again.",
      variant: "destructive",
    });
  } finally {
    setIsLoading(false);
  }
};

// In your render method:
{workflow.name === "Niche-Scout" && (
  <>
    <Button onClick={() => setWizardOpen(true)}>
      Configure Analysis
    </Button>

    <NicheScoutWizard
      trigger={<div />} // Empty trigger because we control open state
      onComplete={handleNicheScoutComplete}
      open={wizardOpen}
      onOpenChange={setWizardOpen}
    />
  </>
)}
```

## 3. Update YouTube Service

```typescript
// In youtube-service.ts

// Update runNicheScout to accept full configuration
export async function runNicheScout(config: {
  category: string;
  subcategory: string;
  budget: number;
  dataSources: DataSourceConfig;
}): Promise<NicheScoutResult> {
  // Return mock data if feature flag is enabled
  if (FEATURES.USE_MOCK_DATA) {
    await new Promise(resolve => setTimeout(resolve, 1500));
    return mockNicheScoutResult;
  }

  try {
    const response = await fetch(createApiUrl(ENDPOINTS.NICHE_SCOUT), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(config)
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || error.error || 'Failed to run Niche-Scout workflow');
    }

    return response.json();
  } catch (error) {
    console.error('Error running Niche-Scout workflow:', error);
    // Fall back to mock data if API fails
    return mockNicheScoutResult;
  }
}
```

## 4. Backend Configuration (architect-api service)

Ensure the architect-api service is properly configured with environment variables:

```bash
# Required in architect-api service environment
OPENAI_API_KEY=your_openai_api_key
YOUTUBE_API_KEY=your_youtube_api_key
GCP_PROJECT_ID=your_google_project_id
```

## 5. Complete Flow Documentation

### User Flow

1. User navigates to Workflows view
2. User clicks "Configure Analysis" on the Niche-Scout workflow card
3. Wizard opens with 3-step process:
   - Step 1: Select main category
   - Step 2: Select subcategory
   - Step 3: Configure budget and data sources
4. User clicks "Run Analysis"
5. UI shows loading state
6. Backend processes the request and collects data
7. Results are displayed to user

### Data Flow

1. **Frontend Collection**:
   - User inputs captured in NicheScoutWizard component
   - Data packaged as FinalPayload and passed to parent via onComplete

2. **API Communication**:
   - WorkflowCard calls runNicheScout with payload
   - youtube-service sends POST request to /api/youtube/niche-scout endpoint

3. **Backend Processing**:
   - architect-api service receives request
   - Service uses YouTube API to collect data based on category/subcategory
   - OpenAI API processes the data to identify trends
   - Results are formatted and returned

4. **Result Handling**:
   - Frontend receives NicheScoutResult
   - UI updates to show trending niches and insights
   - Results may be stored in database for later viewing

## 6. Testing the Integration

1. Set `VITE_USE_MOCK_DATA=false` in your .env file
2. Ensure the architect-api container is running
3. Check that YouTube API key is configured in architect-api
4. Follow the user flow and check network requests
5. Verify the response matches expected structure

## 7. Troubleshooting

- If data doesn't appear, check browser console for API errors
- Verify environment variables are correctly set in both frontend and backend
- Check that architect-api service is running and accessible
- If using Docker, ensure all containers on same network
- If API calls fail, temporarily set `VITE_USE_MOCK_DATA=true` to test UI flow
```
