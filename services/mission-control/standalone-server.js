// Standalone server for improved UI
const express = require('express');
const path = require('path');
const fs = require('fs');

// Create Express application
const app = express();
const PORT = 3007;

// Serve static files from the out directory (Next.js build output)
app.use(express.static(path.join(__dirname, 'out')));

// Setup directory for improved UI files
const UI_DIRECTORY = path.join(__dirname, 'improved-ui');
if (!fs.existsSync(UI_DIRECTORY)) {
  fs.mkdirSync(UI_DIRECTORY, { recursive: true });
}

// Create the improved UI HTML
const improvedNicheScoutHTML = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Improved Niche-Scout Workflow</title>
  <style>
    /* Base styles */
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
      background-color: #f9fafb;
      color: #111827;
      margin: 0;
      padding: 0;
    }

    header {
      background-color: white;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      padding: 1rem;
    }

    h1 {
      font-size: 1.5rem;
      font-weight: bold;
      margin: 0;
    }

    main {
      max-width: 1200px;
      margin: 0 auto;
      padding: 1.5rem;
    }

    .card {
      background-color: white;
      border-radius: 0.5rem;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      padding: 1.5rem;
      margin-bottom: 1.5rem;
    }

    h2 {
      font-size: 1.25rem;
      font-weight: bold;
      margin-top: 0;
      margin-bottom: 1rem;
    }

    /* Wizard indicators */
    .wizard-progress {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 1.5rem;
    }

    .step {
      display: flex;
      align-items: center;
    }

    .step-number {
      width: 2rem;
      height: 2rem;
      border-radius: 9999px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 500;
      margin-right: 0.5rem;
    }

    .step-active .step-number {
      background-color: #e0f2fe;
      color: #0284c7;
    }

    .step-inactive .step-number {
      background-color: #f3f4f6;
      color: #9ca3af;
    }

    .step-label {
      font-size: 0.875rem;
      font-weight: 500;
    }

    .step-active .step-label {
      color: #0284c7;
    }

    .step-inactive .step-label {
      color: #9ca3af;
    }

    .step-divider {
      flex-grow: 1;
      height: 0.125rem;
      background-color: #e5e7eb;
      margin: 0 0.5rem;
    }

    /* Form elements */
    .form-group {
      margin-bottom: 1.5rem;
    }

    label {
      display: block;
      font-size: 0.875rem;
      font-weight: 500;
      margin-bottom: 0.25rem;
      color: #4b5563;
    }

    input, select {
      width: 100%;
      padding: 0.5rem 0.75rem;
      border: 1px solid #d1d5db;
      border-radius: 0.375rem;
      background-color: white;
      font-size: 1rem;
    }

    input:focus, select:focus {
      outline: none;
      box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.5);
      border-color: #3b82f6;
    }

    .help-text {
      font-size: 0.75rem;
      color: #6b7280;
      margin-top: 0.25rem;
    }

    /* Buttons */
    .btn {
      padding: 0.5rem 1rem;
      border-radius: 0.375rem;
      font-weight: 500;
      cursor: pointer;
      display: inline-block;
      text-align: center;
      user-select: none;
      border: none;
    }

    .btn-primary {
      background-color: #2563eb;
      color: white;
    }

    .btn-primary:hover {
      background-color: #1d4ed8;
    }

    .btn-secondary {
      background-color: #e5e7eb;
      color: #1f2937;
    }

    .btn-secondary:hover {
      background-color: #d1d5db;
    }

    /* Layout utilities */
    .flex {
      display: flex;
    }

    .justify-between {
      justify-content: space-between;
    }

    .justify-end {
      justify-content: flex-end;
    }

    .gap-2 {
      gap: 0.5rem;
    }

    .gap-4 {
      gap: 1rem;
    }

    .mt-4 {
      margin-top: 1rem;
    }

    .mb-4 {
      margin-bottom: 1rem;
    }

    /* Grid */
    .grid {
      display: grid;
      gap: 1rem;
    }

    .grid-cols-2 {
      grid-template-columns: repeat(2, 1fr);
    }

    @media (max-width: 640px) {
      .grid-cols-2 {
        grid-template-columns: 1fr;
      }
    }

    /* Subcategory tags */
    .subcategory-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
      gap: 0.5rem;
    }

    .tag {
      padding: 0.5rem;
      border: 1px solid #d1d5db;
      border-radius: 0.25rem;
      cursor: pointer;
      text-align: center;
      transition: all 0.2s;
    }

    .tag:hover {
      transform: translateY(-2px);
    }

    .tag-selected {
      background-color: #e0f2fe;
      border-color: #38bdf8;
      color: #0284c7;
    }

    /* Summary section */
    .summary-card {
      background-color: #f3f4f6;
      border-radius: 0.5rem;
      padding: 1rem;
      margin-bottom: 1rem;
    }

    .summary-item {
      display: flex;
      margin-bottom: 0.5rem;
    }

    .summary-label {
      font-weight: 500;
      width: 8rem;
    }

    .summary-value {
      color: #2563eb;
    }

    /* What you'll get section */
    .benefits-card {
      background-color: #eff6ff;
      border-radius: 0.5rem;
      padding: 1rem;
    }

    .benefits-heading {
      color: #1e40af;
      font-weight: 600;
      margin-top: 0;
      margin-bottom: 0.5rem;
    }

    .benefits-list {
      color: #1d4ed8;
      margin: 0;
      padding-left: 1.5rem;
    }

    .benefits-list li {
      margin-bottom: 0.25rem;
    }

    /* Animation */
    @keyframes fadeIn {
      from {
        opacity: 0;
        transform: translateY(10px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    .animate-in {
      animation: fadeIn 0.3s ease-out;
    }

    /* Schedule modal */
    .modal-backdrop {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-color: rgba(0, 0, 0, 0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 50;
    }

    .modal {
      background-color: white;
      border-radius: 0.5rem;
      padding: 1.5rem;
      width: 100%;
      max-width: 28rem;
      box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
    }

    /* Hide steps that aren't active */
    .step-content {
      display: none;
    }

    .step-content.active {
      display: block;
    }
  </style>
</head>
<body>
  <header>
    <h1>MISSION CONTROL</h1>
  </header>

  <main>
    <div class="pb-5 border-b border-gray-200 mb-6">
      <h1>Niche-Scout Workflow</h1>
    </div>

    <!-- Wizard Progress -->
    <div class="wizard-progress mb-6">
      <div class="step step-active" data-step="1">
        <div class="step-number">1</div>
        <span class="step-label">Define Niche</span>
      </div>
      <div class="step-divider"></div>
      <div class="step step-inactive" data-step="2">
        <div class="step-number">2</div>
        <span class="step-label">Research Parameters</span>
      </div>
      <div class="step-divider"></div>
      <div class="step step-inactive" data-step="3">
        <div class="step-number">3</div>
        <span class="step-label">Review & Run</span>
      </div>
    </div>

    <!-- Step 1: Define Niche -->
    <div id="step-1" class="step-content active animate-in">
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
            <option>All</option>
            <option>Gaming</option>
            <option>Education</option>
            <option>Entertainment</option>
            <option>Howto & Style</option>
            <option>Science & Technology</option>
          </select>
        </div>

        <div id="subcategories-container" class="form-group" style="display: none;">
          <label>Refine with Subcategories (Optional)</label>
          <div id="subcategories" class="subcategory-grid">
            <!-- Subcategories will be added here via JavaScript -->
          </div>
        </div>

        <div class="flex justify-end">
          <button class="btn btn-primary next-step" data-next="2">Next: Research Parameters</button>
        </div>
      </div>
    </div>

    <!-- Step 2: Research Parameters -->
    <div id="step-2" class="step-content">
      <div class="card animate-in">
        <h2>Set Research Parameters</h2>

        <div class="grid grid-cols-2">
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
          <button id="advanced-toggle" class="btn btn-secondary">+ Advanced Options</button>
        </div>

        <div id="advanced-options" style="display: none;" class="form-group">
          <div style="border: 1px solid #d1d5db; border-radius: 0.375rem; padding: 1rem; margin-bottom: 1rem;">
            <h3 style="margin-top: 0; margin-bottom: 0.5rem;">Advanced Filters</h3>

            <div class="grid grid-cols-2">
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
        </div>

        <div class="flex justify-between">
          <button class="btn btn-secondary prev-step" data-prev="1">Back: Define Niche</button>
          <button class="btn btn-primary next-step" data-next="3">Next: Review & Run</button>
        </div>
      </div>
    </div>

    <!-- Step 3: Review & Run -->
    <div id="step-3" class="step-content">
      <div class="card animate-in">
        <h2>Review & Run Analysis</h2>

        <div class="summary-card">
          <h3 style="margin-top: 0; margin-bottom: 0.75rem;">Niche Scout Summary</h3>

          <div class="summary-item">
            <span class="summary-label">Niche Query:</span>
            <span id="summary-query" class="summary-value">(not specified)</span>
          </div>

          <div class="summary-item">
            <span class="summary-label">Category:</span>
            <span id="summary-category" class="summary-value">All</span>
          </div>

          <div id="summary-subcategories-container" class="summary-item" style="display: none;">
            <span class="summary-label">Subcategories:</span>
            <span id="summary-subcategories" class="summary-value"></span>
          </div>

          <div class="summary-item">
            <span class="summary-label">Time Range:</span>
            <span id="summary-timerange" class="summary-value">Last 30 days</span>
          </div>

          <div class="summary-item">
            <span class="summary-label">Demographics:</span>
            <span id="summary-demographics" class="summary-value">All</span>
          </div>
        </div>

        <div class="benefits-card">
          <h3 class="benefits-heading">What You'll Get</h3>

          <ul class="benefits-list">
            <li>Top performing niches based on views and engagement</li>
            <li>Growth rate analysis for trending content areas</li>
            <li>Visual mapping of niche positioning</li>
            <li>Opportunity score for niche competitiveness</li>
            <li>Recommended content strategies</li>
          </ul>
        </div>

        <div class="flex justify-between mt-4">
          <button class="btn btn-secondary prev-step" data-prev="2">Back: Research Parameters</button>

          <div class="flex gap-2">
            <button id="schedule-btn" class="btn btn-secondary">SCHEDULE</button>
            <button id="run-btn" class="btn btn-primary">RUN ANALYSIS NOW</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Schedule Modal (Hidden by default) -->
    <div id="schedule-modal" class="modal-backdrop" style="display: none;">
      <div class="modal">
        <h2 style="margin-top: 0; margin-bottom: 1rem;">Schedule Workflow</h2>

        <div class="form-group">
          <label>Frequency</label>
          <select id="frequency">
            <option value="daily">Daily</option>
            <option value="weekly">Weekly</option>
            <option value="monthly">Monthly</option>
            <option value="once">Once</option>
          </select>
        </div>

        <div id="run-date-container" class="form-group" style="display: none;">
          <label>Run Date</label>
          <input type="datetime-local" id="run-date">
        </div>

        <div class="flex justify-end gap-2">
          <button id="cancel-schedule" class="btn btn-secondary">Cancel</button>
          <button id="confirm-schedule" class="btn btn-primary">Schedule</button>
        </div>
      </div>
    </div>
  </main>

  <script>
    // Subcategories mapping
    const subcategoriesMap = {
      'Gaming': ['FPS Games', 'RPG Games', 'Strategy Games', 'Mobile Gaming', 'Game Reviews'],
      'Education': ['Tutorials', 'Academic', 'Language Learning', 'DIY', 'Science'],
      'Entertainment': ['Comedy', 'Vlogs', 'Reactions', 'Shorts', 'Storytelling'],
      'Howto & Style': ['Beauty', 'Fashion', 'Home Decor', 'Cooking', 'Crafts'],
      'Science & Technology': ['Gadget Reviews', 'Coding', 'AI & ML', 'Engineering', 'Science News']
    };

    // Selected subcategories
    let selectedSubcategories = [];

    // DOM elements
    const stepElements = document.querySelectorAll('.step');
    const stepContentElements = document.querySelectorAll('.step-content');
    const nextButtons = document.querySelectorAll('.next-step');
    const prevButtons = document.querySelectorAll('.prev-step');
    const categorySelect = document.getElementById('category');
    const subcategoriesContainer = document.getElementById('subcategories-container');
    const subcategoriesGrid = document.getElementById('subcategories');
    const advancedToggle = document.getElementById('advanced-toggle');
    const advancedOptions = document.getElementById('advanced-options');
    const scheduleBtn = document.getElementById('schedule-btn');
    const runBtn = document.getElementById('run-btn');
    const scheduleModal = document.getElementById('schedule-modal');
    const frequencySelect = document.getElementById('frequency');
    const runDateContainer = document.getElementById('run-date-container');
    const cancelScheduleBtn = document.getElementById('cancel-schedule');
    const confirmScheduleBtn = document.getElementById('confirm-schedule');

    // Summary elements
    const summaryQuery = document.getElementById('summary-query');
    const summaryCategory = document.getElementById('summary-category');
    const summarySubcategoriesContainer = document.getElementById('summary-subcategories-container');
    const summarySubcategories = document.getElementById('summary-subcategories');
    const summaryTimeRange = document.getElementById('summary-timerange');
    const summaryDemographics = document.getElementById('summary-demographics');

    // Initialize the form
    function init() {
      // Set up event listeners for step navigation
      nextButtons.forEach(button => {
        button.addEventListener('click', () => {
          const nextStep = parseInt(button.dataset.next);
          goToStep(nextStep);
          updateSummary();
        });
      });

      prevButtons.forEach(button => {
        button.addEventListener('click', () => {
          const prevStep = parseInt(button.dataset.prev);
          goToStep(prevStep);
        });
      });

      // Set up category change
      categorySelect.addEventListener('change', updateSubcategories);

      // Set up advanced options toggle
      advancedToggle.addEventListener('click', () => {
        if (advancedOptions.style.display === 'none') {
          advancedOptions.style.display = 'block';
          advancedToggle.textContent = '- Hide Advanced Options';
        } else {
          advancedOptions.style.display = 'none';
          advancedToggle.textContent = '+ Advanced Options';
        }
      });

      // Set up schedule modal
      scheduleBtn.addEventListener('click', () => {
        scheduleModal.style.display = 'flex';
      });

      cancelScheduleBtn.addEventListener('click', () => {
        scheduleModal.style.display = 'none';
      });

      confirmScheduleBtn.addEventListener('click', () => {
        scheduleModal.style.display = 'none';
        alert('Workflow scheduled successfully!');
      });

      frequencySelect.addEventListener('change', () => {
        if (frequencySelect.value === 'once') {
          runDateContainer.style.display = 'block';
        } else {
          runDateContainer.style.display = 'none';
        }
      });

      // Set up run button
      runBtn.addEventListener('click', () => {
        runBtn.textContent = 'Running...';
        runBtn.disabled = true;

        // Simulate API call
        setTimeout(() => {
          alert('Analysis complete! Navigating to results...');
          runBtn.textContent = 'RUN ANALYSIS NOW';
          runBtn.disabled = false;
        }, 2000);
      });

      // Initial subcategories update
      updateSubcategories();
    }

    // Navigate to a specific step
    function goToStep(stepNumber) {
      // Update step indicators
      stepElements.forEach(step => {
        const stepNum = parseInt(step.dataset.step);
        if (stepNum === stepNumber) {
          step.classList.add('step-active');
          step.classList.remove('step-inactive');
        } else if (stepNum < stepNumber) {
          step.classList.add('step-active');
          step.classList.remove('step-inactive');
        } else {
          step.classList.add('step-inactive');
          step.classList.remove('step-active');
        }
      });

      // Show the active step content
      stepContentElements.forEach(content => {
        content.classList.remove('active');
      });
      document.getElementById(\`step-\${stepNumber}\`).classList.add('active');
    }

    // Update subcategories based on selected category
    function updateSubcategories() {
      const category = categorySelect.value;

      if (category !== 'All' && subcategoriesMap[category]) {
        // Show subcategories container
        subcategoriesContainer.style.display = 'block';

        // Clear previously selected subcategories
        selectedSubcategories = [];

        // Create subcategory tags
        subcategoriesGrid.innerHTML = '';
        subcategoriesMap[category].forEach(subcategory => {
          const tag = document.createElement('div');
          tag.className = 'tag';
          tag.textContent = subcategory;
          tag.dataset.subcategory = subcategory;

          tag.addEventListener('click', () => {
            toggleSubcategory(tag, subcategory);
          });

          subcategoriesGrid.appendChild(tag);
        });
      } else {
        // Hide subcategories container
        subcategoriesContainer.style.display = 'none';
        selectedSubcategories = [];
      }

      updateSummary();
    }

    // Toggle selection of a subcategory
    function toggleSubcategory(tagElement, subcategory) {
      const index = selectedSubcategories.indexOf(subcategory);

      if (index === -1) {
        // Add subcategory
        selectedSubcategories.push(subcategory);
        tagElement.classList.add('tag-selected');
      } else {
        // Remove subcategory
        selectedSubcategories.splice(index, 1);
        tagElement.classList.remove('tag-selected');
      }

      updateSummary();
    }

    // Update the summary in step 3
    function updateSummary() {
      // Update query
      const query = document.getElementById('niche-query').value;
      summaryQuery.textContent = query || '(not specified)';

      // Update category
      summaryCategory.textContent = categorySelect.value;

      // Update subcategories
      if (selectedSubcategories.length > 0) {
        summarySubcategoriesContainer.style.display = 'flex';
        summarySubcategories.textContent = selectedSubcategories.join(', ');
      } else {
        summarySubcategoriesContainer.style.display = 'none';
      }

      // Update time range
      summaryTimeRange.textContent = document.getElementById('time-range').value;

      // Update demographics
      summaryDemographics.textContent = document.getElementById('demographics').value;
    }

    // Initialize when DOM is loaded
    document.addEventListener('DOMContentLoaded', init);
  </script>
</body>
</html>
`;

// Write improved UI file
fs.writeFileSync(path.join(UI_DIRECTORY, 'niche-scout.html'), improvedNicheScoutHTML);

// Route for improved Niche-Scout UI
app.get('/workflows/niche-scout', (req, res) => {
  res.sendFile(path.join(UI_DIRECTORY, 'niche-scout.html'));
});

// Route for root path
app.get('/', (req, res) => {
  res.send('Mission Control is running. Access the improved Niche-Scout UI at <a href="/workflows/niche-scout">Niche-Scout Workflow</a>');
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Access the improved Niche-Scout UI at http://localhost:${PORT}/workflows/niche-scout`);
});
