# YouTube API Configuration Guide

## Overview

The YouTube workflows (Niche-Scout and Seed-to-Blueprint) require a valid YouTube API key to interact with the YouTube Data API. This guide explains how to obtain and configure this key for the platform.

## Requirements

1. A Google account
2. A Google Cloud project 
3. YouTube Data API v3 enabled
4. API key with appropriate permissions

## Authentication Requirements

Our YouTube workflows primarily use **read-only operations** to collect data for analysis:

- Search for videos, channels, and trending content
- Retrieve video statistics and metadata
- Analyze video categories and tags

For these operations, a **simple API key is sufficient** - no OAuth 2.0 authorization is required.

> **Note**: OAuth 2.0 would only be required if our platform needed to:
> - Access private user data
> - Perform write operations (upload videos, update metadata, etc.)
> - Manage YouTube account settings
> 
> Our current implementation does not require these capabilities.

## Getting a YouTube API Key

1. **Create or Select a Google Cloud Project**:
   - Go to the [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Note the Project ID (it will be used in the environment variables)

2. **Enable YouTube Data API**:
   - Navigate to "APIs & Services" > "Library"
   - Search for "YouTube Data API v3"
   - Click on it and press "Enable"

3. **Create an API Key**:
   - Navigate to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - A new API key will be created and displayed
   - Optionally, restrict the API key to only the YouTube Data API v3

4. **Set API Restrictions** (Optional but Recommended):
   - After creating the key, click "Edit API key"
   - Under "API restrictions" select "Restrict key"
   - Select "YouTube Data API v3" from the dropdown menu
   - Click "Save"

## Configuring the Platform

1. **Update Environment Variables**:
   - In your `.env` file, add the following line:
   ```
   YOUTUBE_API_KEY=your-youtube-api-key
   ```
   - Replace `your-youtube-api-key` with the actual API key from the Google Cloud Console

2. **Restart the Social Intelligence Agent**:
   - If the platform is already running, restart the social-intel service:
   ```
   docker-compose restart social-intel
   ```
   - Or restart the entire platform:
   ```
   docker-compose down
   docker-compose up -d
   ```

## Testing the Integration

To verify that your YouTube API key is working:

1. Navigate to the Workflows page in the Mission Control UI
2. Find the "Niche-Scout" workflow card
3. Click "Configure Analysis"
4. Complete the wizard and run the analysis
5. Check the browser console for API errors

If the analysis completes successfully without falling back to mock data, your API key is working correctly.

## Quota Management

YouTube Data API has the following quota limits:

- Basic usage: 10,000 units per day (default)
- Each search request typically costs 100 units
- Each video details request costs 1 unit
- List operations cost varying amounts (typically 1-5 units)

Our platform uses these operations approximately as follows:

| Workflow | Operation | Cost per Run | Daily Limit |
|----------|-----------|--------------|-------------|
| Niche-Scout | Search (categories) | ~500 units | ~20 runs |
| Seed-to-Blueprint | Video Details + Related | ~300 units | ~30 runs |

To monitor your usage:
1. Go to Google Cloud Console
2. Navigate to "APIs & Services" > "Dashboard"
3. Select "YouTube Data API v3"
4. View the "Quotas" section

### Quota Management Strategies

To optimize quota usage, we implement:

1. **Result Caching**: Previously returned results are cached to minimize duplicate API calls
2. **Throttling**: Rate limits on workflow execution frequency
3. **Mock Mode**: Using `VITE_USE_MOCK_DATA=true` during development to avoid API calls
4. **Data Reuse**: Sharing common data between related workflows

Consider requesting a quota increase if you plan to run workflows frequently or at scale.

## Troubleshooting

If you encounter issues with the YouTube API:

1. **Verify Key Status**:
   - Check if the key is active in the Google Cloud Console
   - Ensure the YouTube Data API is enabled for the project

2. **Check Quota**:
   - Verify that you haven't exceeded your daily quota limit
   - Request a quota increase if needed

3. **Debug Requests**:
   - Set `DEBUG=true` in your environment variables
   - Check the social-intel service logs: `docker-compose logs -f social-intel`

4. **Testing Mode**:
   - Set `VITE_USE_MOCK_DATA=true` in your frontend `.env` to use mock data during development

For any persistent issues, consult the [YouTube API documentation](https://developers.google.com/youtube/v3/docs).