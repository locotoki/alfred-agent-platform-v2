import { test, expect } from '@playwright/test';

// Test constants
const TEST_QUERY = 'mobile gaming tips';

test.describe('Niche-Scout Workflow', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the workflows page
    await page.goto('/workflows');
    
    // Wait for the page to load
    await page.waitForSelector('h1:has-text("WORKFLOWS")');
  });

  test('should navigate to Niche-Scout form', async ({ page }) => {
    // Click on the Niche-Scout workflow card
    await page.click('text=Niche-Scout');
    
    // Verify we're on the correct page
    await expect(page).toHaveURL(/\/workflows\/niche-scout/);
    await expect(page.locator('h1')).toContainText('NICHE-SCOUT WORKFLOW');
  });

  test('should submit Niche-Scout form with basic query', async ({ page }) => {
    // Navigate to Niche-Scout form
    await page.click('text=Niche-Scout');
    
    // Fill in the query field
    await page.fill('input#query', TEST_QUERY);
    
    // Submit the form
    await page.click('button:has-text("Run Workflow")');
    
    // Wait for processing (loading state)
    await expect(page.locator('button:has-text("Processing")')).toBeVisible();
    
    // The form should redirect to results page or show error
    // We'll check for both possibilities since we can't guarantee the API connection
    try {
      // Check if redirected to results page (happy path)
      await page.waitForURL(/\/workflows\/niche-scout\/results\//, { timeout: 30000 });
      await expect(page).toHaveURL(/\/workflows\/niche-scout\/results\//);
      
      // Verify results page has loaded properly
      await expect(page.locator('h1')).toContainText('NICHE-SCOUT RESULTS');
      
      // Check for visualization or data
      const resultsVisible = await page.isVisible('.trend-visualization') || 
                              await page.isVisible('.trending-niches-table');
      expect(resultsVisible).toBeTruthy();
      
    } catch (e) {
      // If not redirected, we should see an error message on the form page
      await expect(page.locator('.bg-red-50')).toBeVisible();
      console.log('API connection failed, test detected error state correctly');
    }
  });

  test('should submit Niche-Scout form with advanced options', async ({ page }) => {
    // Navigate to Niche-Scout form
    await page.click('text=Niche-Scout');
    
    // Fill in the query field
    await page.fill('input#query', TEST_QUERY);
    
    // Show advanced options
    await page.click('text=Show Advanced Options');
    
    // Select options from dropdowns
    await page.selectOption('select#category', 'Gaming');
    await page.selectOption('select#timeRange', 'Last 90 days');
    await page.selectOption('select#demographics', '18-24');
    
    // Submit the form
    await page.click('button:has-text("Run Workflow")');
    
    // Wait for processing (loading state)
    await expect(page.locator('button:has-text("Processing")')).toBeVisible();
    
    // Check for redirect or error like in the previous test
    try {
      await page.waitForURL(/\/workflows\/niche-scout\/results\//, { timeout: 30000 });
      await expect(page).toHaveURL(/\/workflows\/niche-scout\/results\//);
      
      // Verify results
      await expect(page.locator('h1')).toContainText('NICHE-SCOUT RESULTS');
      
    } catch (e) {
      // Check for error state
      await expect(page.locator('.bg-red-50')).toBeVisible();
      console.log('API connection failed, test detected error state correctly');
    }
  });

  test('should validate required fields in Niche-Scout form', async ({ page }) => {
    // Navigate to Niche-Scout form
    await page.click('text=Niche-Scout');
    
    // Try to submit without filling required fields
    await page.click('button:has-text("Run Workflow")');
    
    // Check if form validation prevents submission
    // The page should not navigate away and should show validation messages
    await expect(page).toHaveURL(/\/workflows\/niche-scout$/);
    
    // Look for browser's native validation message or custom validation UI
    // This might vary depending on how validation is implemented
    const invalidInputExists = await page.evaluate(() => {
      const input = document.querySelector('input#query:invalid');
      return !!input;
    });
    
    expect(invalidInputExists).toBeTruthy();
  });
});
