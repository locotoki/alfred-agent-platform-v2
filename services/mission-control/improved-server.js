// Improved HTTP server to host the Niche-Scout UI with better route handling
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

// HTML content for improved UI
const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Improved Niche-Scout Workflow</title>
  <style>
    body {font-family:system-ui,-apple-system,sans-serif; margin:0; padding:0; background:#f5f7fa;}
    header {background:#fff; box-shadow:0 1px 3px rgba(0,0,0,0.1); padding:1rem;}
    h1 {font-size:1.5rem; margin:0;}
    main {max-width:1200px; margin:0 auto; padding:1.5rem;}
    .card {background:#fff; border-radius:0.5rem; box-shadow:0 2px 4px rgba(0,0,0,0.05); padding:1.5rem; margin-bottom:1.5rem;}
    
    /* Wizard Progress */
    .steps {display:flex; margin-bottom:2rem; position:relative;}
    .steps::before {content:""; position:absolute; top:14px; left:24px; right:24px; height:2px; background:#e2e8f0; z-index:0;}
    .step {flex:1; display:flex; flex-direction:column; align-items:center; position:relative; z-index:1;}
    .step-circle {width:30px; height:30px; border-radius:50%; display:flex; align-items:center; justify-content:center; margin-bottom:0.5rem; background:#fff; border:2px solid #e2e8f0; color:#64748b; font-weight:600;}
    .step.active .step-circle, .step.completed .step-circle {background:#3b82f6; border-color:#3b82f6; color:#fff;}
    .step-text {font-size:0.875rem; color:#64748b; font-weight:500;}
    .step.active .step-text {color:#3b82f6; font-weight:600;}
    
    /* Form Elements */
    .form-group {margin-bottom:1.5rem;}
    label {display:block; font-size:0.875rem; font-weight:500; margin-bottom:0.5rem; color:#4b5563;}
    input, select {width:100%; padding:0.75rem; border:1px solid #d1d5db; border-radius:0.375rem; font-size:1rem;}
    .help-text {font-size:0.75rem; color:#6b7280; margin-top:0.25rem;}
    
    /* Grid Layout */
    .grid {display:grid; gap:1.5rem;}
    .grid-2 {grid-template-columns:repeat(2, 1fr);}
    @media (max-width:768px) {.grid-2 {grid-template-columns:1fr;}}
    
    /* Button Styles */
    .btn {padding:0.75rem 1.5rem; border-radius:0.375rem; font-weight:500; cursor:pointer; display:inline-flex; align-items:center; justify-content:center; transition:all 0.2s;}
    .btn-primary {background:#3b82f6; color:#fff; border:none;}
    .btn-primary:hover {background:#2563eb;}
    .btn-secondary {background:#f3f4f6; color:#374151; border:1px solid #d1d5db;}
    .btn-secondary:hover {background:#e5e7eb;}
    
    /* Layout Utilities */
    .flex {display:flex;}
    .flex-wrap {flex-wrap:wrap;}
    .justify-between {justify-content:space-between;}
    .justify-end {justify-content:flex-end;}
    .gap-2 {gap:0.5rem;}
    .mt-6 {margin-top:1.5rem;}
    
    /* Step Content Animation */
    @keyframes fadeIn {
      from {opacity:0; transform:translateY(10px);}
      to {opacity:1; transform:translateY(0);}
    }
    .step-content {display:none;}
    .step-content.active {display:block; animation:fadeIn 0.3s ease-out;}
    
    /* Subcategory Tags */
    .subcategory-grid {display:grid; grid-template-columns:repeat(auto-fill, minmax(150px, 1fr)); gap:0.5rem;}
    .tag {padding:0.5rem; border:1px solid #d1d5db; border-radius:0.375rem; text-align:center; cursor:pointer; transition:all 0.2s;}
    .tag:hover {transform:translateY(-2px); border-color:#93c5fd;}
    .tag.selected {background:#eff6ff; border-color:#3b82f6; color:#2563eb;}
    
    /* Summary Section */
    .summary-section {background:#f8fafc; border-radius:0.5rem; padding:1.5rem; margin-bottom:1.5rem;}
    .summary-item {display:flex; margin-bottom:0.5rem;}
    .summary-label {font-weight:500; width:8rem;}
    .summary-value {color:#3b82f6;}
    
    /* Benefits Section */
    .benefits-section {background:#eff6ff; border-radius:0.5rem; padding:1.5rem;}
    .benefits-title {color:#1e40af; margin-top:0;}
    .benefits-list {color:#1d4ed8;}
    .benefits-list li {margin-bottom:0.5rem;}
  </style>
</head>
<body>
  <header>
    <h1>MISSION CONTROL</h1>
  </header>
  
  <main>
    <div style="border-bottom:1px solid #e2e8f0; margin-bottom:1.5rem; padding-bottom:1rem;">
      <h1>Niche-Scout Workflow</h1>
    </div>
    
    <!-- Wizard Steps -->
    <div class="steps">
      <div class="step active" data-step="1">
        <div class="step-circle">1</div>
        <div class="step-text">Define Niche</div>
      </div>
      <div class="step" data-step="2">
        <div class="step-circle">2</div>
        <div class="step-text">Research Parameters</div>
      </div>
      <div class="step" data-step="3">
        <div class="step-circle">3</div>
        <div class="step-text">Review & Run</div>
      </div>
    </div>
    
    <!-- Step 1: Define Niche -->
    <div id="step-1" class="step-content active">
      <div class="card">
        <h2>Define Your Niche</h2>
        
        <div class="form-group">
          <label for="niche-query">What niche are you interested in exploring?</label>
          <input id="niche-query" type="text" placeholder="e.g. gaming, cooking, fitness, photography">
          <p class="help-text">Enter keywords that describe your content area of interest</p>
        </div>
        
        <div class="form-group">
          <label for="category">Select a Primary Category</label>
          <select id="category">
            <option value="All">All</option>
            <option value="Gaming">Gaming</option>
            <option value="Education">Education</option>
            <option value="Entertainment">Entertainment</option>
            <option value="Howto & Style">Howto & Style</option>
            <option value="Science & Technology">Science & Technology</option>
          </select>
        </div>
        
        <div id="subcategories-container" class="form-group" style="display:none;">
          <label>Refine with Subcategories (Optional)</label>
          <div id="subcategories-grid" class="subcategory-grid"></div>
        </div>
        
        <div class="flex justify-end mt-6">
          <button id="next-1" class="btn btn-primary">Next: Research Parameters</button>
        </div>
      </div>
    </div>
    
    <!-- Step 2: Research Parameters -->
    <div id="step-2" class="step-content">
      <div class="card">
        <h2>Set Research Parameters</h2>
        
        <div class="grid grid-2">
          <div class="form-group">
            <label for="time-range">Time Range</label>
            <select id="time-range">
              <option>Last 7 days</option>
              <option selected>Last 30 days</option>
              <option>Last 90 days</option>
              <option>Last 12 months</option>
            </select>
            <p class="help-text">Select how far back to analyze trends</p>
          </div>
          
          <div class="form-group">
            <label for="demographics">Target Demographics</label>
            <select id="demographics">
              <option selected>All</option>
              <option>13-17</option>
              <option>18-24</option>
              <option>25-34</option>
              <option>35-44</option>
              <option>45+</option>
            </select>
            <p class="help-text">Filter results by audience age group</p>
          </div>
        </div>
        
        <div class="form-group">
          <button id="toggle-advanced" class="btn btn-secondary">+ Advanced Options</button>
        </div>
        
        <div id="advanced-options" style="display:none; border:1px solid #e2e8f0; border-radius:0.5rem; padding:1rem; margin-bottom:1.5rem;">
          <h3 style="margin-top:0;">Advanced Filters</h3>
          
          <div class="grid grid-2">
            <div class="form-group">
              <label for="min-views">Minimum Views</label>
              <input id="min-views" type="number" placeholder="e.g. 10000">
              <p class="help-text">Exclude videos with fewer views</p>
            </div>
            
            <div class="form-group">
              <label for="min-growth">Minimum Growth (%)</label>
              <input id="min-growth" type="number" placeholder="e.g. 20">
              <p class="help-text">Focus on rapidly growing niches</p>
            </div>
          </div>
        </div>
        
        <div class="flex justify-between mt-6">
          <button id="prev-2" class="btn btn-secondary">Back: Define Niche</button>
          <button id="next-2" class="btn btn-primary">Next: Review & Run</button>
        </div>
      </div>
    </div>
    
    <!-- Step 3: Review & Run -->
    <div id="step-3" class="step-content">
      <div class="card">
        <h2>Review & Run Analysis</h2>
        
        <div class="summary-section">
          <h3 style="margin-top:0; margin-bottom:1rem;">Niche Scout Summary</h3>
          
          <div class="summary-item">
            <div class="summary-label">Niche Query:</div>
            <div id="summary-query" class="summary-value">(not specified)</div>
          </div>
          
          <div class="summary-item">
            <div class="summary-label">Category:</div>
            <div id="summary-category" class="summary-value">All</div>
          </div>
          
          <div id="summary-subcategories-container" class="summary-item" style="display:none;">
            <div class="summary-label">Subcategories:</div>
            <div id="summary-subcategories" class="summary-value"></div>
          </div>
          
          <div class="summary-item">
            <div class="summary-label">Time Range:</div>
            <div id="summary-timerange" class="summary-value">Last 30 days</div>
          </div>
          
          <div class="summary-item">
            <div class="summary-label">Demographics:</div>
            <div id="summary-demographics" class="summary-value">All</div>
          </div>
        </div>
        
        <div class="benefits-section">
          <h3 class="benefits-title">What You'll Get</h3>
          
          <ul class="benefits-list">
            <li>Top performing niches based on views and engagement</li>
            <li>Growth rate analysis for trending content areas</li>
            <li>Visual mapping of niche positioning</li>
            <li>Opportunity score for niche competitiveness</li>
            <li>Recommended content strategies</li>
          </ul>
        </div>
        
        <div class="flex justify-between mt-6">
          <button id="prev-3" class="btn btn-secondary">Back: Research Parameters</button>
          
          <div class="flex gap-2">
            <button id="schedule-btn" class="btn btn-secondary">SCHEDULE</button>
            <button id="run-btn" class="btn btn-primary">RUN ANALYSIS NOW</button>
          </div>
        </div>
      </div>
    </div>
  </main>
  
  <script>
    // Subcategories data
    const subcategoriesMap = {
      'Gaming': ['FPS Games', 'RPG Games', 'Strategy Games', 'Mobile Gaming', 'Game Reviews'],
      'Education': ['Tutorials', 'Academic', 'Language Learning', 'DIY', 'Science'],
      'Entertainment': ['Comedy', 'Vlogs', 'Reactions', 'Shorts', 'Storytelling'],
      'Howto & Style': ['Beauty', 'Fashion', 'Home Decor', 'Cooking', 'Crafts'],
      'Science & Technology': ['Gadget Reviews', 'Coding', 'AI & ML', 'Engineering', 'Science News']
    };
    
    // Initialize selected subcategories
    let selectedSubcategories = [];
    
    // DOM references
    const steps = document.querySelectorAll('.step');
    const stepContents = document.querySelectorAll('.step-content');
    const categorySelect = document.getElementById('category');
    const subcategoriesContainer = document.getElementById('subcategories-container');
    const subcategoriesGrid = document.getElementById('subcategories-grid');
    const toggleAdvanced = document.getElementById('toggle-advanced');
    const advancedOptions = document.getElementById('advanced-options');
    const scheduleBtn = document.getElementById('schedule-btn');
    const runBtn = document.getElementById('run-btn');
    
    // Summary elements
    const summaryQuery = document.getElementById('summary-query');
    const summaryCategory = document.getElementById('summary-category');
    const summarySubcategoriesContainer = document.getElementById('summary-subcategories-container');
    const summarySubcategories = document.getElementById('summary-subcategories');
    const summaryTimeRange = document.getElementById('summary-timerange');
    const summaryDemographics = document.getElementById('summary-demographics');
    
    // Navigation handlers
    document.getElementById('next-1').addEventListener('click', () => goToStep(2));
    document.getElementById('prev-2').addEventListener('click', () => goToStep(1));
    document.getElementById('next-2').addEventListener('click', () => {
      updateSummary();
      goToStep(3);
    });
    document.getElementById('prev-3').addEventListener('click', () => goToStep(2));
    
    // Advanced options toggle
    toggleAdvanced.addEventListener('click', () => {
      if (advancedOptions.style.display === 'none') {
        advancedOptions.style.display = 'block';
        toggleAdvanced.textContent = '- Hide Advanced Options';
      } else {
        advancedOptions.style.display = 'none';
        toggleAdvanced.textContent = '+ Advanced Options';
      }
    });
    
    // Run workflow button
    runBtn.addEventListener('click', () => {
      const originalText = runBtn.textContent;
      runBtn.textContent = 'Running...';
      runBtn.disabled = true;
      
      // Simulate API call
      setTimeout(() => {
        alert('Analysis complete! Navigating to results page...');
        runBtn.textContent = originalText;
        runBtn.disabled = false;
      }, 2000);
    });
    
    // Schedule button
    scheduleBtn.addEventListener('click', () => {
      alert('Workflow scheduled successfully!');
    });
    
    // Category change handler
    categorySelect.addEventListener('change', updateSubcategories);
    
    // Navigate to step
    function goToStep(stepNumber) {
      // Update steps
      steps.forEach(step => {
        const num = parseInt(step.dataset.step);
        if (num === stepNumber) {
          step.classList.add('active');
        } else if (num < stepNumber) {
          step.classList.add('completed');
          step.classList.remove('active');
        } else {
          step.classList.remove('active', 'completed');
        }
      });
      
      // Update content
      stepContents.forEach(content => {
        content.classList.remove('active');
      });
      document.getElementById('step-' + stepNumber).classList.add('active');
    }
    
    // Update subcategories based on selected category
    function updateSubcategories() {
      const category = categorySelect.value;
      
      if (category !== 'All' && subcategoriesMap[category]) {
        subcategoriesContainer.style.display = 'block';
        subcategoriesGrid.innerHTML = '';
        
        subcategoriesMap[category].forEach(subcategory => {
          const tag = document.createElement('div');
          tag.className = 'tag';
          tag.textContent = subcategory;
          
          // Check if already selected
          if (selectedSubcategories.includes(subcategory)) {
            tag.classList.add('selected');
          }
          
          tag.addEventListener('click', () => {
            toggleSubcategory(tag, subcategory);
          });
          
          subcategoriesGrid.appendChild(tag);
        });
      } else {
        subcategoriesContainer.style.display = 'none';
        selectedSubcategories = [];
      }
    }
    
    // Toggle subcategory selection
    function toggleSubcategory(element, subcategory) {
      if (element.classList.contains('selected')) {
        element.classList.remove('selected');
        selectedSubcategories = selectedSubcategories.filter(item => item !== subcategory);
      } else {
        element.classList.add('selected');
        selectedSubcategories.push(subcategory);
      }
    }
    
    // Update summary information
    function updateSummary() {
      const query = document.getElementById('niche-query').value;
      summaryQuery.textContent = query || '(not specified)';
      
      summaryCategory.textContent = categorySelect.value;
      
      if (selectedSubcategories.length > 0) {
        summarySubcategoriesContainer.style.display = 'flex';
        summarySubcategories.textContent = selectedSubcategories.join(', ');
      } else {
        summarySubcategoriesContainer.style.display = 'none';
      }
      
      summaryTimeRange.textContent = document.getElementById('time-range').value;
      summaryDemographics.textContent = document.getElementById('demographics').value;
    }
    
    // Initialize subcategories
    updateSubcategories();
  </script>
</body>
</html>
`;

// Index page HTML
const indexHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mission Control Dashboard</title>
  <style>
    body {
      font-family: system-ui, -apple-system, sans-serif;
      background-color: #f5f7fa;
      margin: 0;
      padding: 0;
    }
    header {
      background-color: #fff;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      padding: 1rem;
      margin-bottom: 2rem;
    }
    h1 {
      font-size: 1.5rem;
      margin: 0;
    }
    main {
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 1.5rem;
    }
    .link-card {
      display: block;
      padding: 1.5rem;
      background-color: white;
      border-radius: 0.5rem;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      margin-bottom: 1rem;
      text-decoration: none;
      color: inherit;
      transition: all 0.2s;
    }
    .link-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    .link-card h2 {
      margin-top: 0;
      color: #3b82f6;
    }
  </style>
</head>
<body>
  <header>
    <h1>MISSION CONTROL</h1>
  </header>
  
  <main>
    <div style="border-bottom:1px solid #e2e8f0; margin-bottom:2rem; padding-bottom:1rem;">
      <h1>YouTube Workflow Dashboard</h1>
    </div>
    
    <a href="/workflows/niche-scout" class="link-card">
      <h2>Niche-Scout Workflow</h2>
      <p>Discover trending niches and content opportunities on YouTube</p>
    </a>
    
    <a href="#" class="link-card">
      <h2>Seed-to-Blueprint Workflow</h2>
      <p>Convert content ideas into detailed production blueprints</p>
    </a>
  </main>
</body>
</html>
`;

// Create server
const server = http.createServer((req, res) => {
  // Parse URL
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  
  console.log(`[${new Date().toISOString()}] Request received: ${req.method} ${pathname}`);
  
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Handle requests
  if (pathname === '/' || pathname === '/index.html') {
    // Serve index page
    console.log('Serving index page');
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.write(indexHtml);
    res.end();
  } 
  else if (pathname === '/workflows/niche-scout' || pathname === '/workflows/niche-scout/') {
    // Serve Niche-Scout page
    console.log('Serving Niche-Scout page');
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.write(htmlContent);
    res.end();
  }
  else {
    // Log the 404 error details
    console.log(`404 Not Found: ${pathname}`);
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.write(`404 Not Found: ${pathname}\n\nAvailable routes:\n- /\n- /workflows/niche-scout`);
    res.end();
  }
});

// Start server
const PORT = 3007;
server.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}/`);
  console.log(`Root page: http://localhost:${PORT}/`);
  console.log(`Niche-Scout UI: http://localhost:${PORT}/workflows/niche-scout`);
  console.log(`Server started at: ${new Date().toISOString()}`);
});
