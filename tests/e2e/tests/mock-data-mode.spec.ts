import { test, expect } from '@playwright/test';
import { setupMockDataMode } from './utils';

test.describe('YouTube Workflows with Mock Data', () => {
  test.beforeEach(async ({ page }) => {
    // Set up mock data interception
    await setupMockDataMode(page);

    // Navigate to the workflows page
    await page.goto('/workflows');

    // Wait for the page to load
    await page.waitForSelector('h1:has-text("WORKFLOWS")');
  });

  test('should complete Niche-Scout workflow with mock data', async ({ page }) => {
    // Navigate to Niche-Scout form
    await page.click('text=Niche-Scout');

    // Fill in the query field
    await page.fill('input#query', 'test query with mock data');

    // Submit the form
    await page.click('button:has-text("Run Workflow")');

    // Wait for redirection to results page
    await page.waitForURL(/\/workflows\/niche-scout\/results\//, { timeout: 30000 });

    // Verify results page has loaded with mock data
    await expect(page.locator('h1')).toContainText('NICHE-SCOUT RESULTS');

    // Look for specific mock data patterns
    const pageContent = await page.content();
    expect(pageContent).toContain('mobile gaming tips');
  });

  test('should complete Seed-to-Blueprint workflow with mock data', async ({ page }) => {
    // Navigate to Seed-to-Blueprint form
    await page.click('text=Seed-to-Blueprint');

    // Select 'Use Seed Video' option
    await page.click('text=Use Seed Video');

    // Fill in the video URL field
    await page.fill('input#video_url', 'https://www.youtube.com/watch?v=mockvideo');

    // Submit the form
    await page.click('button:has-text("Run Workflow")');

    // Wait for redirection to results page
    await page.waitForURL(/\/workflows\/seed-to-blueprint\/results\//, { timeout: 30000 });

    // Verify results page has loaded with mock data
    await expect(page.locator('h1')).toContainText('BLUEPRINT RESULTS');

    // Look for specific mock data patterns
    const pageContent = await page.content();
    expect(pageContent).toContain('Tips & Tricks');
    expect(pageContent).toContain('Performance Optimization');
  });
});
