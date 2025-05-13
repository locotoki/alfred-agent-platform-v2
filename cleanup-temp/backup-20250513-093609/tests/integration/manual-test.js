// Manual Playwright test script for YouTube workflows
const { chromium } = require('playwright');

async function runTest() {
  // Launch browser
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    console.log('Opening Mission Control...');
    // Go to workflows page
    await page.goto('http://localhost:3005/workflows');
    await page.waitForLoadState('networkidle');
    
    // Confirm we're on the workflows page
    console.log('Looking for workflows page elements...');
    if (await page.isVisible('text=WORKFLOWS')) {
      console.log('✅ Successfully loaded workflows page');
    } else {
      console.log('❌ Failed to find workflows header - is Mission Control running?');
    }
    
    // Click on Niche Scout
    console.log('Navigating to Niche-Scout workflow...');
    await page.click('text=Niche-Scout');
    await page.waitForLoadState('networkidle');
    
    // Confirm we're on the Niche Scout page
    if (await page.isVisible('text=NICHE-SCOUT WORKFLOW')) {
      console.log('✅ Successfully loaded Niche-Scout workflow page');
    } else {
      console.log('❌ Failed to find Niche-Scout header');
    }
    
    // Fill in the form
    console.log('Filling form with test query...');
    await page.fill('input#query', 'mobile gaming tips 2025');
    
    // Open advanced options
    await page.click('text=Show Advanced Options');
    
    // Set some advanced options if they exist
    try {
      await page.selectOption('select#category', 'Gaming');
      await page.selectOption('select#timeRange', 'Last 90 days');
      console.log('✅ Set advanced options');
    } catch (e) {
      console.log('⚠️ Could not set all advanced options:', e.message);
    }
    
    // Submit the form
    console.log('Submitting form...');
    await page.click('button:has-text("Run Workflow")');
    
    // Wait for the form submission - look for processing state
    console.log('Waiting for processing...');
    try {
      await page.waitForSelector('button:has-text("Processing")', { timeout: 5000 });
      console.log('✅ Found processing indicator');
    } catch (e) {
      console.log('⚠️ Did not see processing indicator:', e.message);
    }
    
    // Wait for redirect to results page
    console.log('Waiting for redirect to results page (this may take up to 30 seconds)...');
    try {
      await page.waitForURL(/\/workflows\/niche-scout\/results\//, { timeout: 30000 });
      console.log('✅ Successfully redirected to results page');
      
      // Verify results page has loaded properly
      if (await page.isVisible('text=NICHE-SCOUT RESULTS')) {
        console.log('✅ Results page header found');
      } else {
        console.log('❌ Results page header not found');
      }
      
      // Check for visualization or data
      const resultsVisible = await page.isVisible('.trend-visualization') || 
                             await page.isVisible('.trending-niches-table');
      if (resultsVisible) {
        console.log('✅ Found visualization or results table');
        
        // Take a screenshot for verification
        await page.screenshot({ path: 'niche-scout-results.png' });
        console.log('✅ Screenshot saved as niche-scout-results.png');
      } else {
        console.log('❌ No visualization or results table found');
      }
    } catch (e) {
      console.log('❌ Failed to reach results page:', e.message);
      
      // Check if we're seeing an error message on the form page
      if (await page.isVisible('.bg-red-50') || await page.isVisible('.error')) {
        console.log('⚠️ Error message detected on form');
        const errorText = await page.textContent('.bg-red-50, .error');
        console.log('Error message:', errorText);
      } else {
        console.log('No error message visible on form');
      }
      
      // Take a screenshot of current state
      await page.screenshot({ path: 'niche-scout-error.png' });
      console.log('✅ Screenshot saved as niche-scout-error.png');
    }
    
    // Pause to view the results
    console.log('Pausing for 10 seconds to view results...');
    await new Promise(r => setTimeout(r, 10000));
    
    // Now test Seed-to-Blueprint workflow
    console.log('\n--- Testing Seed-to-Blueprint Workflow ---\n');
    
    // Go back to workflows page
    await page.goto('http://localhost:3005/workflows');
    await page.waitForLoadState('networkidle');
    
    // Click on Seed-to-Blueprint
    console.log('Navigating to Seed-to-Blueprint workflow...');
    await page.click('text=Seed-to-Blueprint');
    await page.waitForLoadState('networkidle');
    
    // Confirm we're on the Blueprint page
    if (await page.isVisible('text=SEED-TO-BLUEPRINT WORKFLOW')) {
      console.log('✅ Successfully loaded Seed-to-Blueprint workflow page');
    } else {
      console.log('❌ Failed to find Seed-to-Blueprint header');
    }
    
    // Select niche input option if it exists
    try {
      await page.click('text=Use Niche Keyword');
      console.log('✅ Selected niche input option');
    } catch (e) {
      console.log('⚠️ Could not select niche input option, trying with default video URL');
    }
    
    // Fill in the form based on available options
    if (await page.isVisible('input#niche')) {
      console.log('Filling niche input...');
      await page.fill('input#niche', 'mobile gaming tutorials');
    } else if (await page.isVisible('input#video_url')) {
      console.log('Filling video URL input...');
      await page.fill('input#video_url', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    } else {
      console.log('❌ Could not find either niche or video_url input');
    }
    
    // Submit the form
    console.log('Submitting form...');
    await page.click('button:has-text("Run Workflow")');
    
    // Wait for the form submission - look for processing state
    console.log('Waiting for processing...');
    try {
      await page.waitForSelector('button:has-text("Processing")', { timeout: 5000 });
      console.log('✅ Found processing indicator');
    } catch (e) {
      console.log('⚠️ Did not see processing indicator:', e.message);
    }
    
    // Wait for redirect to results page
    console.log('Waiting for redirect to results page (this may take up to 45 seconds)...');
    try {
      await page.waitForURL(/\/workflows\/seed-to-blueprint\/results\//, { timeout: 45000 });
      console.log('✅ Successfully redirected to results page');
      
      // Verify results page has loaded properly
      if (await page.isVisible('text=BLUEPRINT RESULTS')) {
        console.log('✅ Results page header found');
      } else {
        console.log('❌ Results page header not found');
      }
      
      // Check for results data
      const resultsVisible = await page.isVisible('.blueprint-visualization') || 
                             await page.isVisible('.blueprint-results');
      if (resultsVisible) {
        console.log('✅ Found blueprint results');
        
        // Take a screenshot for verification
        await page.screenshot({ path: 'blueprint-results.png' });
        console.log('✅ Screenshot saved as blueprint-results.png');
      } else {
        console.log('❌ No blueprint results found');
      }
    } catch (e) {
      console.log('❌ Failed to reach results page:', e.message);
      
      // Check if we're seeing an error message on the form page
      if (await page.isVisible('.bg-red-50') || await page.isVisible('.error')) {
        console.log('⚠️ Error message detected on form');
        const errorText = await page.textContent('.bg-red-50, .error');
        console.log('Error message:', errorText);
      } else {
        console.log('No error message visible on form');
      }
      
      // Take a screenshot of current state
      await page.screenshot({ path: 'blueprint-error.png' });
      console.log('✅ Screenshot saved as blueprint-error.png');
    }
    
    // Pause to view the results
    console.log('Pausing for 10 seconds to view results...');
    await new Promise(r => setTimeout(r, 10000));
    
  } catch (error) {
    console.error('Test failed with error:', error);
  } finally {
    // Close browser
    await browser.close();
    console.log('Test complete!');
  }
}

runTest();