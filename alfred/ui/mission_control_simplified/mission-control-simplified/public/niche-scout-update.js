/**
 * Proxy service integration for Niche-Scout UI
 *
 * This script adds support for the proxy service to the Niche-Scout UI,
 * allowing users to view and configure the proxy service.
 */

// Add proxy configuration tab
document.addEventListener('DOMContentLoaded', function() {
  // Add proxy tab to result tabs
  const resultTabs = document.querySelector('.result-tabs');
  if (resultTabs) {
    const proxyTab = document.createElement('div');
    proxyTab.className = 'result-tab';
    proxyTab.dataset.tab = 'proxy';
    proxyTab.textContent = 'Proxy Config';
    resultTabs.appendChild(proxyTab);

    // Add proxy content
    const resultsContainer = document.getElementById('results-container');
    if (resultsContainer) {
      const proxyContent = document.createElement('div');
      proxyContent.id = 'proxy-tab';
      proxyContent.className = 'result-content';

      proxyContent.innerHTML = `
        <h3>Proxy Service Configuration</h3>

        <div class="summary-section">
          <h4>Current Configuration</h4>
          <div id="proxy-status">Loading proxy configuration...</div>

          <div style="margin-top: 1rem;">
            <button id="refresh-proxy-config" class="btn btn-secondary">Refresh Configuration</button>
          </div>
        </div>

        <div style="margin-top: 1.5rem;">
          <h4>Update Configuration</h4>

          <div style="background: #f1f5f9; border-radius: 0.375rem; padding: 1rem; margin: 1rem 0;">
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
              <div>
                <label for="proxy-similarity-threshold" style="display: block; font-size: 0.875rem; margin-bottom: 0.25rem;">Similarity Threshold</label>
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                  <input type="range" id="proxy-similarity-threshold" min="0.1" max="0.9" step="0.05" value="0.55" style="flex-grow: 1;">
                  <span id="proxy-threshold-value" style="font-size: 0.875rem; font-weight: 500; min-width: 2.5rem; text-align: center;">0.55</span>
                </div>
              </div>

              <div>
                <label for="proxy-niche-count" style="display: block; font-size: 0.875rem; margin-bottom: 0.25rem;">Niche Count</label>
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                  <input type="range" id="proxy-niche-count" min="3" max="10" step="1" value="5" style="flex-grow: 1;">
                  <span id="proxy-count-value" style="font-size: 0.875rem; font-weight: 500; min-width: 2.5rem; text-align: center;">5</span>
                </div>
              </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 0.5rem;">
              <div>
                <label for="proxy-weight-levenshtein" style="display: block; font-size: 0.75rem; margin-bottom: 0.25rem;">Levenshtein Weight</label>
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                  <input type="range" id="proxy-weight-levenshtein" min="0.1" max="0.9" step="0.1" value="0.5" style="flex-grow: 1;">
                  <span id="proxy-levenshtein-value" style="font-size: 0.75rem; min-width: 2rem; text-align: center;">0.5</span>
                </div>
              </div>

              <div>
                <label for="proxy-weight-jaccard" style="display: block; font-size: 0.75rem; margin-bottom: 0.25rem;">Jaccard Weight</label>
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                  <input type="range" id="proxy-weight-jaccard" min="0.1" max="0.9" step="0.1" value="0.3" style="flex-grow: 1;">
                  <span id="proxy-jaccard-value" style="font-size: 0.75rem; min-width: 2rem; text-align: center;">0.3</span>
                </div>
              </div>

              <div>
                <label for="proxy-weight-jaro" style="display: block; font-size: 0.75rem; margin-bottom: 0.25rem;">Jaro-Winkler Weight</label>
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                  <input type="range" id="proxy-weight-jaro" min="0.1" max="0.9" step="0.1" value="0.2" style="flex-grow: 1;">
                  <span id="proxy-jaro-value" style="font-size: 0.75rem; min-width: 2rem; text-align: center;">0.2</span>
                </div>
              </div>
            </div>

            <div style="margin-top: 1rem;">
              <div>
                <label for="proxy-cache-enabled" style="display: block; font-size: 0.875rem; margin-bottom: 0.25rem;">Cache</label>
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                  <label style="display: flex; align-items: center; gap: 0.5rem;">
                    <input type="checkbox" id="proxy-cache-enabled" checked>
                    <span>Enable caching</span>
                  </label>
                </div>
              </div>

              <div style="margin-top: 0.5rem;">
                <label for="proxy-cache-ttl" style="display: block; font-size: 0.875rem; margin-bottom: 0.25rem;">Cache TTL (seconds)</label>
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                  <input type="number" id="proxy-cache-ttl" min="60" max="86400" step="60" value="3600" style="width: 150px;">
                </div>
              </div>
            </div>

            <div style="margin-top: 0.75rem; display: flex; justify-content: space-between;">
              <button id="proxy-reset-config" class="btn btn-secondary" style="font-size: 0.75rem; padding: 0.25rem 0.5rem;">Reset to Defaults</button>
              <button id="proxy-apply-config" class="btn btn-primary" style="font-size: 0.75rem; padding: 0.25rem 0.5rem;">Apply Changes</button>
            </div>
          </div>
        </div>

        <div style="margin-top: 1.5rem;">
          <h4>Proxy Metrics</h4>
          <p>View detailed metrics in Prometheus at <a href="http://localhost:9090" target="_blank">http://localhost:9090</a></p>

          <div style="margin-top: 1rem;">
            <button id="view-prometheus" class="btn btn-secondary">Open Prometheus</button>
          </div>
        </div>
      `;

      resultsContainer.appendChild(proxyContent);

      // Add tab click handler
      proxyTab.addEventListener('click', () => {
        document.querySelectorAll('.result-tab').forEach(t => t.classList.remove('active'));
        proxyTab.classList.add('active');

        document.querySelectorAll('.result-content').forEach(content => {
          content.classList.remove('active');
        });

        proxyContent.classList.add('active');

        // Load proxy configuration
        loadProxyConfig();
      });

      // Initialize proxy configuration UI
      initProxyConfigUI();
    }
  }
});

// Load proxy configuration
function loadProxyConfig() {
  const proxyStatus = document.getElementById('proxy-status');
  if (!proxyStatus) return;

  fetch('/api/proxy/config')
    .then(response => response.json())
    .then(data => {
      if (!data.enabled) {
        proxyStatus.innerHTML = `
          <div style="padding: 1rem; background-color: #fee2e2; border-radius: 0.375rem; color: #b91c1c;">
            <strong>Proxy Service is Disabled</strong>
            <p>The proxy service is currently disabled. Enable it in the server configuration to use proxy features.</p>
          </div>
        `;
        return;
      }

      // Update status
      proxyStatus.innerHTML = `
        <div style="padding: 1rem; background-color: #dcfce7; border-radius: 0.375rem; color: #166534;">
          <strong>Proxy Service is Enabled</strong>
          <p>Current traffic percentage: ${data.trafficPercentage}%</p>
          <p>Proxy URL: ${data.url}</p>
        </div>

        <div style="margin-top: 1rem;">
          <h5>Active Configuration</h5>
          <pre style="background: #f1f5f9; padding: 0.5rem; border-radius: 0.375rem; font-size: 0.75rem; overflow: auto;">${JSON.stringify(data.config, null, 2)}</pre>
        </div>
      `;

      // Update UI controls with current values
      updateProxyControls(data.config);
    })
    .catch(error => {
      console.error('Error loading proxy configuration:', error);
      proxyStatus.innerHTML = `
        <div style="padding: 1rem; background-color: #fee2e2; border-radius: 0.375rem; color: #b91c1c;">
          <strong>Failed to Load Proxy Configuration</strong>
          <p>${error.message}</p>
        </div>
      `;
    });
}

// Initialize proxy configuration UI
function initProxyConfigUI() {
  // Refresh button
  const refreshButton = document.getElementById('refresh-proxy-config');
  if (refreshButton) {
    refreshButton.addEventListener('click', loadProxyConfig);
  }

  // Prometheus button
  const prometheusButton = document.getElementById('view-prometheus');
  if (prometheusButton) {
    prometheusButton.addEventListener('click', () => {
      window.open('http://localhost:9090', '_blank');
    });
  }

  // Slider controls
  const similaritySlider = document.getElementById('proxy-similarity-threshold');
  const thresholdValue = document.getElementById('proxy-threshold-value');

  if (similaritySlider && thresholdValue) {
    similaritySlider.addEventListener('input', () => {
      thresholdValue.textContent = similaritySlider.value;
    });
  }

  const nicheCountSlider = document.getElementById('proxy-niche-count');
  const countValue = document.getElementById('proxy-count-value');

  if (nicheCountSlider && countValue) {
    nicheCountSlider.addEventListener('input', () => {
      countValue.textContent = nicheCountSlider.value;
    });
  }

  const levenshteinSlider = document.getElementById('proxy-weight-levenshtein');
  const levenshteinValue = document.getElementById('proxy-levenshtein-value');

  if (levenshteinSlider && levenshteinValue) {
    levenshteinSlider.addEventListener('input', () => {
      levenshteinValue.textContent = levenshteinSlider.value;
      updateWeights('levenshtein');
    });
  }

  const jaccardSlider = document.getElementById('proxy-weight-jaccard');
  const jaccardValue = document.getElementById('proxy-jaccard-value');

  if (jaccardSlider && jaccardValue) {
    jaccardSlider.addEventListener('input', () => {
      jaccardValue.textContent = jaccardSlider.value;
      updateWeights('jaccard');
    });
  }

  const jaroSlider = document.getElementById('proxy-weight-jaro');
  const jaroValue = document.getElementById('proxy-jaro-value');

  if (jaroSlider && jaroValue) {
    jaroSlider.addEventListener('input', () => {
      jaroValue.textContent = jaroSlider.value;
      updateWeights('jaro');
    });
  }

  // Apply button
  const applyButton = document.getElementById('proxy-apply-config');
  if (applyButton) {
    applyButton.addEventListener('click', applyProxyConfig);
  }

  // Reset button
  const resetButton = document.getElementById('proxy-reset-config');
  if (resetButton) {
    resetButton.addEventListener('click', resetProxyConfig);
  }
}

// Update algorithm weights to ensure they sum to 1.0
function updateWeights(changedWeight) {
  const levenshteinSlider = document.getElementById('proxy-weight-levenshtein');
  const jaccardSlider = document.getElementById('proxy-weight-jaccard');
  const jaroSlider = document.getElementById('proxy-weight-jaro');

  const levenshteinValue = document.getElementById('proxy-levenshtein-value');
  const jaccardValue = document.getElementById('proxy-jaccard-value');
  const jaroValue = document.getElementById('proxy-jaro-value');

  if (!levenshteinSlider || !jaccardSlider || !jaroSlider) return;

  const levenshtein = parseFloat(levenshteinSlider.value);
  const jaccard = parseFloat(jaccardSlider.value);
  const jaro = parseFloat(jaroSlider.value);

  const sum = levenshtein + jaccard + jaro;

  if (Math.abs(sum - 1.0) > 0.05) {
    // Adjust the other weights proportionally
    if (changedWeight !== 'levenshtein') {
      const newLevenshtein = Math.max(0.1, Math.min(0.9, levenshtein * (1.0 / sum)));
      levenshteinSlider.value = newLevenshtein.toFixed(1);
      levenshteinValue.textContent = newLevenshtein.toFixed(1);
    }

    if (changedWeight !== 'jaccard') {
      const newJaccard = Math.max(0.1, Math.min(0.9, jaccard * (1.0 / sum)));
      jaccardSlider.value = newJaccard.toFixed(1);
      jaccardValue.textContent = newJaccard.toFixed(1);
    }

    if (changedWeight !== 'jaro') {
      const newJaro = Math.max(0.1, Math.min(0.9, jaro * (1.0 / sum)));
      jaroSlider.value = newJaro.toFixed(1);
      jaroValue.textContent = newJaro.toFixed(1);
    }
  }
}

// Update proxy controls with current values
function updateProxyControls(config) {
  const similaritySlider = document.getElementById('proxy-similarity-threshold');
  const thresholdValue = document.getElementById('proxy-threshold-value');
  const nicheCountSlider = document.getElementById('proxy-niche-count');
  const countValue = document.getElementById('proxy-count-value');

  const levenshteinSlider = document.getElementById('proxy-weight-levenshtein');
  const levenshteinValue = document.getElementById('proxy-levenshtein-value');
  const jaccardSlider = document.getElementById('proxy-weight-jaccard');
  const jaccardValue = document.getElementById('proxy-jaccard-value');
  const jaroSlider = document.getElementById('proxy-weight-jaro');
  const jaroValue = document.getElementById('proxy-jaro-value');

  const cacheEnabled = document.getElementById('proxy-cache-enabled');
  const cacheTtl = document.getElementById('proxy-cache-ttl');

  if (config.transformation) {
    if (similaritySlider && thresholdValue && config.transformation.similarityThreshold) {
      similaritySlider.value = config.transformation.similarityThreshold;
      thresholdValue.textContent = config.transformation.similarityThreshold;
    }

    if (nicheCountSlider && countValue && config.transformation.defaultNicheCount) {
      nicheCountSlider.value = config.transformation.defaultNicheCount;
      countValue.textContent = config.transformation.defaultNicheCount;
    }

    if (config.transformation.algorithmWeights) {
      const weights = config.transformation.algorithmWeights;

      if (levenshteinSlider && levenshteinValue && weights.levenshtein !== undefined) {
        levenshteinSlider.value = weights.levenshtein;
        levenshteinValue.textContent = weights.levenshtein;
      }

      if (jaccardSlider && jaccardValue && weights.jaccard !== undefined) {
        jaccardSlider.value = weights.jaccard;
        jaccardValue.textContent = weights.jaccard;
      }

      if (jaroSlider && jaroValue && weights.jaroWinkler !== undefined) {
        jaroSlider.value = weights.jaroWinkler;
        jaroValue.textContent = weights.jaroWinkler;
      }
    }
  }

  if (config.cache) {
    if (cacheEnabled && config.cache.enabled !== undefined) {
      cacheEnabled.checked = config.cache.enabled;
    }

    if (cacheTtl && config.cache.ttl !== undefined) {
      cacheTtl.value = config.cache.ttl;
    }
  }
}

// Apply proxy configuration
function applyProxyConfig() {
  const similaritySlider = document.getElementById('proxy-similarity-threshold');
  const nicheCountSlider = document.getElementById('proxy-niche-count');
  const levenshteinSlider = document.getElementById('proxy-weight-levenshtein');
  const jaccardSlider = document.getElementById('proxy-weight-jaccard');
  const jaroSlider = document.getElementById('proxy-weight-jaro');
  const cacheEnabled = document.getElementById('proxy-cache-enabled');
  const cacheTtl = document.getElementById('proxy-cache-ttl');

  const config = {
    transformation: {
      similarityThreshold: parseFloat(similaritySlider.value),
      defaultNicheCount: parseInt(nicheCountSlider.value),
      algorithmWeights: {
        levenshtein: parseFloat(levenshteinSlider.value),
        jaccard: parseFloat(jaccardSlider.value),
        jaroWinkler: parseFloat(jaroSlider.value)
      }
    },
    cache: {
      enabled: cacheEnabled.checked,
      ttl: parseInt(cacheTtl.value)
    }
  };

  fetch('/api/proxy/config', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(config)
  })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        alert('Proxy configuration updated successfully!');
        loadProxyConfig(); // Refresh the configuration
      } else {
        alert(`Failed to update configuration: ${data.message}`);
      }
    })
    .catch(error => {
      console.error('Error updating proxy configuration:', error);
      alert(`Failed to update configuration: ${error.message}`);
    });
}

// Reset proxy configuration to defaults
function resetProxyConfig() {
  const similaritySlider = document.getElementById('proxy-similarity-threshold');
  const thresholdValue = document.getElementById('proxy-threshold-value');
  const nicheCountSlider = document.getElementById('proxy-niche-count');
  const countValue = document.getElementById('proxy-count-value');

  const levenshteinSlider = document.getElementById('proxy-weight-levenshtein');
  const levenshteinValue = document.getElementById('proxy-levenshtein-value');
  const jaccardSlider = document.getElementById('proxy-weight-jaccard');
  const jaccardValue = document.getElementById('proxy-jaccard-value');
  const jaroSlider = document.getElementById('proxy-weight-jaro');
  const jaroValue = document.getElementById('proxy-jaro-value');

  const cacheEnabled = document.getElementById('proxy-cache-enabled');
  const cacheTtl = document.getElementById('proxy-cache-ttl');

  // Set default values
  similaritySlider.value = 0.55;
  thresholdValue.textContent = '0.55';

  nicheCountSlider.value = 5;
  countValue.textContent = '5';

  levenshteinSlider.value = 0.5;
  levenshteinValue.textContent = '0.5';

  jaccardSlider.value = 0.3;
  jaccardValue.textContent = '0.3';

  jaroSlider.value = 0.2;
  jaroValue.textContent = '0.2';

  cacheEnabled.checked = true;
  cacheTtl.value = 3600;
}

// Add the proxy feature toggle to the UI
function addProxyToggle() {
  const debugPanel = document.getElementById('debug-panel');
  if (!debugPanel) return;

  const proxyToggleContainer = document.createElement('div');
  proxyToggleContainer.style.marginTop = '1rem';
  proxyToggleContainer.style.padding = '0.5rem';
  proxyToggleContainer.style.backgroundColor = '#eff6ff';
  proxyToggleContainer.style.borderRadius = '0.375rem';

  proxyToggleContainer.innerHTML = `
    <div style="display: flex; justify-content: space-between; align-items: center;">
      <div>
        <strong>Proxy Routing</strong>
        <div style="font-size: 0.75rem; color: #64748b;">Use proxy service for this request</div>
      </div>
      <label style="display: flex; align-items: center; gap: 0.5rem;">
        <input type="checkbox" id="toggle-proxy-routing">
        <span>Enable</span>
      </label>
    </div>
  `;

  // Insert before metrics history
  const metricsHistory = document.getElementById('metric-history');
  if (metricsHistory) {
    debugPanel.insertBefore(proxyToggleContainer, metricsHistory);
  } else {
    debugPanel.appendChild(proxyToggleContainer);
  }

  // Add event listener
  const proxyToggle = document.getElementById('toggle-proxy-routing');
  if (proxyToggle) {
    proxyToggle.addEventListener('change', () => {
      // Store in localStorage
      localStorage.setItem('useProxyRouting', proxyToggle.checked);
    });

    // Load from localStorage
    const savedSetting = localStorage.getItem('useProxyRouting');
    if (savedSetting !== null) {
      proxyToggle.checked = savedSetting === 'true';
    }
  }
}

// Add proxy toggle to debug panel
document.addEventListener('DOMContentLoaded', function() {
  const debugPanelToggle = document.getElementById('debug-panel-toggle');
  if (debugPanelToggle) {
    // Wait for debug panel to be shown
    const observer = new MutationObserver((mutations, obs) => {
      const debugPanel = document.getElementById('debug-panel');
      if (debugPanel && debugPanel.style.display !== 'none') {
        addProxyToggle();
        obs.disconnect(); // Stop observing
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['style']
    });
  }
});

// Modify the run button to use proxy feature flag
document.addEventListener('DOMContentLoaded', function() {
  const runBtn = document.getElementById('run-btn');
  if (runBtn) {
    const originalFetch = window.fetch;

    window.fetch = function(url, options) {
      // Only intercept our API call
      if (url === '/api/workflows/niche-scout' && options && options.method === 'POST') {
        // Check if proxy routing is enabled
        const useProxyRouting = localStorage.getItem('useProxyRouting') === 'true';

        if (useProxyRouting) {
          // Clone options
          const newOptions = { ...options };

          // Add header to request proxy routing
          newOptions.headers = { ...newOptions.headers, 'x-use-proxy': 'true' };

          return originalFetch(url, newOptions);
        }
      }

      // Otherwise proceed normally
      return originalFetch(url, options);
    };
  }
});
