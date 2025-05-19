# UI Updates for Proxy Integration

This document outlines the UI changes needed to show when the proxy service is being used.

## 1. Add Proxy Badge

Add the following code to the niche-scout.html file before the closing `</body>` tag:

```html
<!-- Proxy badge -->
<div id="proxy-badge" style="display: none; position: fixed; bottom: 20px; right: 20px; background-color: rgba(59, 130, 246, 0.9); color: white; padding: 8px 12px; border-radius: 8px; font-size: 12px; font-weight: 600; box-shadow: 0 2px 5px rgba(0,0,0,0.2); z-index: 1000;">
  <span id="proxy-badge-text">Powered by Proxy</span>
</div>

<script>
  // Show badge when proxy is used
  window.addEventListener('niche_scout_response', function(event) {
    const data = event.detail;
    const proxyBadge = document.getElementById('proxy-badge');
    const proxyBadgeText = document.getElementById('proxy-badge-text');

    if (data && data._routedThroughProxy) {
      proxyBadge.style.display = 'block';

      // Show cache status if available
      if (data.meta && data.meta.cache_hit) {
        proxyBadgeText.textContent = 'Proxy Cache Hit';
        proxyBadge.style.backgroundColor = 'rgba(16, 185, 129, 0.9)'; // Green
      } else {
        proxyBadgeText.textContent = 'Powered by Proxy';
        proxyBadge.style.backgroundColor = 'rgba(59, 130, 246, 0.9)'; // Blue
      }
    } else {
      proxyBadge.style.display = 'none';
    }
  });
</script>
```

## 2. Update API Response Processing

Modify the fetch response handler in niche-scout.html to dispatch an event:

```javascript
.then(data => {
  // Show results
  wizardContainer.style.display = 'none';
  resultsContainer.style.display = 'block';

  // Update result data
  resultDate.textContent = new Date().toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
  resultQuery.textContent = query;
  resultCategory.textContent = category;

  // Log the received data so we can see what we're getting
  console.log('Received API data:', data);

  // Dispatch event for proxy badge
  const responseEvent = new CustomEvent('niche_scout_response', {
    detail: data
  });
  window.dispatchEvent(responseEvent);

  // Rest of the handler...
})
```

## 3. Add Feature Flag to Enable/Disable Proxy

Add a feature flag control to the debug panel:

```html
<div style="margin-top: 1rem; padding: 0.5rem; background-color: #eff6ff; border-radius: 0.375rem;">
  <div style="display: flex; justify-content: space-between; align-items: center;">
    <div>
      <strong>Proxy Rollout</strong>
      <div style="font-size: 0.75rem; color: #64748b;">Current rollout percentage: <span id="proxy-rollout-percentage">0</span>%</div>
    </div>
    <div>
      <button id="check-proxy-status" class="btn btn-secondary" style="font-size: 0.75rem; padding: 0.25rem 0.5rem;">Check Status</button>
    </div>
  </div>
</div>
```

## 4. Add Status Check Function

Add this function to check the proxy status:

```javascript
// Check proxy status
document.getElementById('check-proxy-status').addEventListener('click', function() {
  fetch('/api/health')
    .then(response => response.json())
    .then(data => {
      const percentage = document.getElementById('proxy-rollout-percentage');
      if (data.proxyEnabled) {
        percentage.textContent = data.proxyTrafficPercentage || 0;
        alert(`Proxy is enabled with ${data.proxyTrafficPercentage || 0}% traffic routing.`);
      } else {
        percentage.textContent = '0';
        alert('Proxy is currently disabled.');
      }
    })
    .catch(error => {
      console.error('Error checking proxy status:', error);
      alert('Error checking proxy status.');
    });
});
```

## Implementation Steps

1. Add the proxy badge HTML and script before the closing `</body>` tag in niche-scout.html
2. Update the fetch response handler in the existing code to dispatch the event
3. Add the feature flag control to the debug panel in niche-scout.html
4. Add the status check function to the script section

These changes will provide visual indication when the proxy service is being used, along with configuration visibility from the UI.
