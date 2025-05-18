# Phase 2: Test & QA Matrix

This document outlines the comprehensive testing strategy for the Advanced Analytics features in Phase 2 of the Social Intelligence service.

## Test Coverage Matrix

| Component | Unit Tests | Integration Tests | Performance Tests | Visual Tests | Security Tests |
|-----------|------------|-------------------|-------------------|--------------|----------------|
| **Trend Analytics Engine** | ✅ | ✅ | ✅ | N/A | ✅ |
| **ML Recommendation System** | ✅ | ✅ | ✅ | N/A | ✅ |
| **Analytics API Endpoints** | ✅ | ✅ | ✅ | N/A | ✅ |
| **Vector Search Implementation** | ✅ | ✅ | ✅ | N/A | ✅ |
| **Cross-Platform Collectors** | ✅ | ✅ | ✅ | N/A | ✅ |
| **Analytics Dashboard UI** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Trend Visualization Components** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Competitor Heatmap** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Database Schema Changes** | ✅ | ✅ | ✅ | N/A | ✅ |

## Unit Testing

### Trend Analytics Engine

```typescript
// Example Test Specs

describe('TrendAnalyticsEngine', () => {
  describe('calculateTrendDirection', () => {
    it('should identify rising trend when slope > 0.05', () => {
      const data = generateTimeSeriesData({ slope: 0.06, days: 14 });
      const result = calculateTrendDirection(data);
      expect(result.direction).toBe('rising');
      expect(result.confidence).toBeGreaterThan(0.7);
    });

    it('should identify stable trend when slope is between -0.03 and 0.03', () => {
      const data = generateTimeSeriesData({ slope: 0.02, days: 14 });
      const result = calculateTrendDirection(data);
      expect(result.direction).toBe('stable');
    });

    it('should handle sparse data points gracefully', () => {
      const data = generateSparseTimeSeriesData();
      const result = calculateTrendDirection(data);
      expect(result).not.toBeNull();
      expect(result.confidence).toBeLessThan(0.6); // Lower confidence expected
    });
  });

  describe('forecastTrend', () => {
    it('should forecast future values with appropriate confidence intervals', () => {
      const historicalData = loadFixture('trend_data_14_days.json');
      const forecast = forecastTrend(historicalData, { days: 7 });

      expect(forecast.points).toHaveLength(7);
      expect(forecast.points[0].confidence_upper).toBeGreaterThan(forecast.points[0].value);
      expect(forecast.points[0].confidence_lower).toBeLessThan(forecast.points[0].value);

      // Confidence interval should widen with time
      const firstDayInterval = forecast.points[0].confidence_upper - forecast.points[0].confidence_lower;
      const lastDayInterval = forecast.points[6].confidence_upper - forecast.points[6].confidence_lower;
      expect(lastDayInterval).toBeGreaterThan(firstDayInterval);
    });
  });
});
```

### ML Recommendation Tests

```python
# Example Test Specs

class TestRecommendationEngine:
    def test_content_recommendation_relevance(self):
        """Test that content recommendations are relevant to the niche."""
        test_niche = {"niche_id": 123, "phrase": "gaming tutorials"}
        recommendations = recommend_content(test_niche, count=5)

        # Check recommendation relevance
        for rec in recommendations:
            assert relevance_score(rec["title"], test_niche["phrase"]) > 0.6

    def test_personalization_effect(self):
        """Test that recommendations differ based on user history."""
        test_niche = {"niche_id": 123, "phrase": "gaming tutorials"}

        # User with gaming history
        user1 = {"user_id": "user1", "history": [{"category": "FPS games"}, {"category": "RPG games"}]}

        # User with tech history
        user2 = {"user_id": "user2", "history": [{"category": "programming"}, {"category": "web development"}]}

        rec1 = recommend_content(test_niche, user=user1, count=5)
        rec2 = recommend_content(test_niche, user=user2, count=5)

        # Recommendations should differ
        assert similarity_score(rec1, rec2) < 0.5

        # Recommendations should align with user interests
        for rec in rec1:
            assert any(tag in rec["keywords"] for tag in ["fps", "rpg", "game"])

        for rec in rec2:
            assert any(tag in rec["keywords"] for tag in ["coding", "tutorial", "development"])
```

## Integration Testing

### API Integration Tests

```javascript
// Example Test Specs

describe('Analytics API Integration', () => {
  describe('GET /trend-chart', () => {
    it('should return valid time-series data for existing niche', async () => {
      const response = await request(app)
        .get('/trend-chart')
        .query({ niche_id: 123, timeframe: '90d' })
        .set('Authorization', `Bearer ${testToken}`);

      expect(response.status).toBe(200);
      expect(response.body.series).toBeInstanceOf(Array);
      expect(response.body.series.length).toBeGreaterThan(0);

      // Validate series structure
      const series = response.body.series[0];
      expect(series.metric).toBeDefined();
      expect(series.data).toBeInstanceOf(Array);
      expect(series.data.length).toBeGreaterThan(30); // At least 30 data points for 90 days

      // Validate data point structure
      const dataPoint = series.data[0];
      expect(dataPoint.date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      expect(typeof dataPoint.value).toBe('number');
      expect(dataPoint.type).toMatch(/^(historical|forecast)$/);
    });

    it('should handle forecast parameter correctly', async () => {
      const response = await request(app)
        .get('/trend-chart')
        .query({
          niche_id: 123,
          timeframe: '90d',
          forecast: true,
          forecast_days: 14
        })
        .set('Authorization', `Bearer ${testToken}`);

      expect(response.status).toBe(200);

      // Check for forecast data points
      const series = response.body.series[0];
      const forecastPoints = series.data.filter(point => point.type === 'forecast');
      expect(forecastPoints.length).toBe(14);
    });
  });

  describe('GET /cross-platform-analysis', () => {
    it('should integrate data from multiple platforms', async () => {
      const response = await request(app)
        .get('/cross-platform-analysis')
        .query({
          niche_id: 123,
          platforms: 'youtube,tiktok,instagram'
        })
        .set('Authorization', `Bearer ${testToken}`);

      expect(response.status).toBe(200);
      expect(response.body.cross_platform_data).toBeDefined();

      // Check platform-specific data
      expect(response.body.cross_platform_data.youtube).toBeDefined();
      expect(response.body.cross_platform_data.tiktok).toBeDefined();
      expect(response.body.cross_platform_data.instagram).toBeDefined();

      // Check insights
      expect(response.body.insights).toBeInstanceOf(Array);
      expect(response.body.insights.length).toBeGreaterThan(0);
    });
  });
});
```

### Database Integration Tests

```python
# Example Test Specs

class TestAnalyticsDatabaseIntegration:
    @pytest.fixture(autouse=True)
    def setup_database(self):
        """Set up test database with sample data."""
        # Run migrations
        run_migrations()

        # Seed test data
        seed_test_analytics_data()

        yield

        # Cleanup
        cleanup_test_data()

    def test_trend_cache_functionality(self):
        """Test that trend calculations are properly cached."""
        # First call should calculate and cache
        start_time = time.time()
        result1 = get_trend_analysis(niche_id=123, timeframe="90d")
        first_call_time = time.time() - start_time

        # Second call should use cache
        start_time = time.time()
        result2 = get_trend_analysis(niche_id=123, timeframe="90d")
        second_call_time = time.time() - start_time

        # Verify results match
        assert result1 == result2

        # Verify second call was significantly faster (cached)
        assert second_call_time < (first_call_time / 5)

        # Verify cache entry in database
        cache_entry = get_trend_cache_entry(niche_id=123, timeframe="90d")
        assert cache_entry is not None
        assert cache_entry["valid_until"] > datetime.now()
```

## Performance Testing

### k6 Load Test Scenarios

```javascript
// Trend Analytics Load Test
import { check, sleep } from 'k6';
import http from 'k6/http';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('error_rate');

export const options = {
  scenarios: {
    trend_analytics_load: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '30s', target: 10 },
        { duration: '1m', target: 50 },
        { duration: '2m', target: 100 },
        { duration: '1m', target: 50 },
        { duration: '30s', target: 0 },
      ],
      gracefulRampDown: '30s',
    },
  },
  thresholds: {
    'http_req_duration{endpoint:trend-chart}': ['p95<500'],
    'http_req_duration{endpoint:competitor-heatmap}': ['p95<800'],
    'http_req_duration{endpoint:cross-platform-analysis}': ['p95<1200'],
    'error_rate': ['rate<0.01'],
  },
};

const API_BASE_URL = 'http://localhost:9000';
const API_TOKEN = 'test-token';

export default function() {
  // Test trend chart endpoint with different parameters
  const trendChart = http.get(`${API_BASE_URL}/trend-chart?niche_id=123&timeframe=90d`, {
    headers: { 'Authorization': `Bearer ${API_TOKEN}` },
    tags: { endpoint: 'trend-chart' }
  });

  check(trendChart, {
    'trend-chart status is 200': (r) => r.status === 200,
    'trend-chart response has series data': (r) => r.json().series && r.json().series.length > 0,
  }) || errorRate.add(1);

  sleep(1);

  // Test competitor heatmap endpoint
  const heatmap = http.get(`${API_BASE_URL}/competitor-heatmap?niche_id=123&dimensions=10`, {
    headers: { 'Authorization': `Bearer ${API_TOKEN}` },
    tags: { endpoint: 'competitor-heatmap' }
  });

  check(heatmap, {
    'heatmap status is 200': (r) => r.status === 200,
    'heatmap response has valid data': (r) => r.json().heatmap_data && r.json().heatmap_data.values,
  }) || errorRate.add(1);

  sleep(1);

  // Test cross-platform analysis endpoint
  const crossPlatform = http.get(`${API_BASE_URL}/cross-platform-analysis?niche_id=123`, {
    headers: { 'Authorization': `Bearer ${API_TOKEN}` },
    tags: { endpoint: 'cross-platform-analysis' }
  });

  check(crossPlatform, {
    'cross-platform status is 200': (r) => r.status === 200,
    'cross-platform response has platform data': (r) =>
      r.json().cross_platform_data &&
      r.json().cross_platform_data.youtube &&
      r.json().cross_platform_data.tiktok,
  }) || errorRate.add(1);

  sleep(1);
}
```

### Database Performance Tests

```python
# Example Test Specs

class TestDatabasePerformance:
    @pytest.mark.performance
    def test_analytics_query_performance(self):
        """Test performance of common analytics queries."""
        # Generate test data volume
        generate_large_test_dataset(records=100000)

        # Test trending niches query
        start_time = time.time()
        trending_niches = get_trending_niches(limit=50)
        query_time = time.time() - start_time

        assert query_time < 0.2  # Should complete in under 200ms
        assert len(trending_niches) == 50

        # Test historical trend query
        start_time = time.time()
        trend_data = get_historical_trend(niche_id=123, days=365)
        query_time = time.time() - start_time

        assert query_time < 0.5  # Should complete in under 500ms
        assert len(trend_data) > 300  # Should have most days of data
```

## Visual Regression Testing

### Dashboard UI Tests

```javascript
// Example Visual Regression Tests

describe('Analytics Dashboard Visual Tests', () => {
  beforeEach(async () => {
    await page.goto('http://localhost:3000/analytics-dashboard');
    await page.waitForSelector('.dashboard-loaded');
  });

  it('should display trend chart correctly', async () => {
    await page.click('#trend-chart-tab');
    await page.waitForSelector('#trend-chart svg');

    // Take screenshot for comparison
    const screenshot = await page.screenshot({
      selector: '#trend-chart',
      fullPage: false
    });

    // Compare with baseline
    expect(screenshot).toMatchImageSnapshot({
      failureThreshold: 0.01,
      failureThresholdType: 'percent'
    });
  });

  it('should display competitor heatmap with correct color scaling', async () => {
    await page.click('#competitor-tab');
    await page.waitForSelector('#heatmap-container .heatmap-cell');

    // Take screenshot of the heatmap
    const screenshot = await page.screenshot({
      selector: '#heatmap-container',
      fullPage: false
    });

    // Compare with baseline
    expect(screenshot).toMatchImageSnapshot({
      failureThreshold: 0.01,
      failureThresholdType: 'percent'
    });

    // Check color scales are applied correctly
    const highValueCell = await page.$eval('.heatmap-cell[data-value="0.9"]', el => {
      return window.getComputedStyle(el).backgroundColor;
    });

    const lowValueCell = await page.$eval('.heatmap-cell[data-value="0.1"]', el => {
      return window.getComputedStyle(el).backgroundColor;
    });

    // High values should be more intense than low values
    expect(highValueCell).not.toEqual(lowValueCell);
  });

  it('should render cross-platform comparison charts correctly', async () => {
    await page.click('#cross-platform-tab');
    await page.waitForSelector('#platform-comparison-chart');

    // Take screenshot of the comparison chart
    const screenshot = await page.screenshot({
      selector: '#platform-comparison-chart',
      fullPage: false
    });

    // Compare with baseline
    expect(screenshot).toMatchImageSnapshot({
      failureThreshold: 0.01,
      failureThresholdType: 'percent'
    });
  });
});
```

## Security Testing

### OWASP Top 10 Test Cases

```typescript
// Example Security Test Specs

describe('Analytics API Security Tests', () => {
  // A1:2021 - Broken Access Control
  describe('Access Control Tests', () => {
    it('should reject requests without authentication', async () => {
      const response = await request(app).get('/trend-chart?niche_id=123');
      expect(response.status).toBe(401);
    });

    it('should respect role-based permissions', async () => {
      // Basic user without admin privileges
      const basicUserToken = generateTokenForUser({ id: 'user1', roles: ['basic'] });

      // Try to access admin-only endpoint
      const response = await request(app)
        .get('/admin/analytics-config')
        .set('Authorization', `Bearer ${basicUserToken}`);

      expect(response.status).toBe(403);
    });

    it('should prevent horizontal privilege escalation', async () => {
      // User trying to access another user's data
      const userToken = generateTokenForUser({ id: 'user1', roles: ['basic'] });

      const response = await request(app)
        .get('/user-analytics-history')
        .query({ user_id: 'user2' })
        .set('Authorization', `Bearer ${userToken}`);

      expect(response.status).toBe(403);
    });
  });

  // A3:2021 - Injection
  describe('Injection Prevention Tests', () => {
    it('should sanitize inputs to prevent SQL injection', async () => {
      const response = await request(app)
        .get('/trend-chart')
        .query({ niche_id: "123; DROP TABLE features; --" })
        .set('Authorization', `Bearer ${testToken}`);

      // Should either reject the malicious input or sanitize it
      expect(response.status).not.toBe(500);
      // Verify database integrity after test
      const tableExists = await checkTableExists('features');
      expect(tableExists).toBe(true);
    });

    it('should sanitize inputs to prevent NoSQL injection', async () => {
      const response = await request(app)
        .get('/trend-chart')
        .query({ niche_id: '{"$gt": ""}' })
        .set('Authorization', `Bearer ${testToken}`);

      // Should reject the malicious input
      expect(response.status).toBe(400);
    });
  });

  // A7:2021 - Identification and Authentication Failures
  describe('Authentication Security Tests', () => {
    it('should detect and reject brute force attempts', async () => {
      // Simulate multiple failed login attempts
      for (let i = 0; i < 10; i++) {
        await request(app)
          .post('/auth/login')
          .send({ username: 'admin', password: `wrong-password-${i}` });
      }

      // Next attempt should be blocked even with correct credentials
      const response = await request(app)
        .post('/auth/login')
        .send({ username: 'admin', password: 'correct-password' });

      expect(response.status).toBe(429); // Too Many Requests
    });

    it('should invalidate tokens after password change', async () => {
      // Login and get token
      const loginResponse = await request(app)
        .post('/auth/login')
        .send({ username: 'test-user', password: 'test-password' });

      const oldToken = loginResponse.body.token;

      // Change password
      await request(app)
        .post('/auth/change-password')
        .set('Authorization', `Bearer ${oldToken}`)
        .send({ oldPassword: 'test-password', newPassword: 'new-test-password' });

      // Try to use old token
      const response = await request(app)
        .get('/trend-chart')
        .query({ niche_id: 123 })
        .set('Authorization', `Bearer ${oldToken}`);

      expect(response.status).toBe(401);
    });
  });
});
```

## Test Automation Strategy

### CI/CD Pipeline Integration

The following tests will be integrated into the CI/CD pipeline:

1. **Pull Request Pipeline**:
   - Unit tests
   - Integration tests
   - Security scans (SAST)
   - Linting and style checks
   - Build verification

2. **Nightly Pipeline**:
   - Full test suite including UI tests
   - Performance tests
   - Load tests
   - Security scans (DAST)
   - Database schema validation

3. **Pre-Release Pipeline**:
   - End-to-end tests
   - Visual regression tests
   - Cross-browser testing
   - Accessibility testing
   - Production environment verification

### Test Environment Strategy

| Environment | Purpose | Data | Refresh Cycle |
|-------------|---------|------|---------------|
| **Development** | Feature development | Anonymized sample data | Daily |
| **Integration** | API testing | Production-like data | Weekly |
| **Staging** | Pre-release verification | Production clone | Before each release |
| **Performance** | Load testing | High-volume synthetic data | On-demand |

## Test Data Management

### Test Data Sources

- **Sample Dataset**: Small fixed dataset for unit tests (< 100 records)
- **Anonymized Data**: Production data with PII removed for integration tests
- **Synthetic Data Generator**: Script to generate high-volume test data
- **Snapshot Data**: Point-in-time copies of production data for regression testing

### Test Data Approach

```javascript
// Example Test Data Generator

function generateTestDataset(options = {}) {
  const {
    nicheCount = 100,
    daysOfHistory = 90,
    includeOutliers = true,
    platforms = ['youtube', 'tiktok', 'instagram']
  } = options;

  const dataset = {
    niches: [],
    trend_data: {},
    cross_platform_metrics: {}
  };

  // Generate niches
  for (let i = 0; i < nicheCount; i++) {
    const niche = {
      niche_id: 1000 + i,
      phrase: `Test Niche ${i}`,
      demand_score: randomScore(),
      supply_score: randomScore(),
      monetise_score: randomScore()
    };

    niche.opportunity = (niche.demand_score * niche.monetise_score) /
                         Math.max(niche.supply_score, 0.01);

    dataset.niches.push(niche);

    // Generate trend data
    dataset.trend_data[niche.niche_id] = [];

    let baseValue = randomScore();
    const trendDirection = Math.random() > 0.5 ? 0.01 : -0.01;

    for (let day = 0; day < daysOfHistory; day++) {
      // Add some randomness to trend
      const randomVariation = (Math.random() - 0.5) * 0.05;
      baseValue = Math.max(0, Math.min(1, baseValue + trendDirection + randomVariation));

      // Add some weekly seasonality
      const dayOfWeek = day % 7;
      const seasonality = dayOfWeek === 0 || dayOfWeek === 6 ? 0.1 : 0;

      let value = baseValue + seasonality;

      // Add outliers occasionally
      if (includeOutliers && Math.random() > 0.98) {
        value = Math.random() > 0.5 ? Math.min(1, value * 1.5) : Math.max(0, value * 0.5);
      }

      const date = new Date();
      date.setDate(date.getDate() - (daysOfHistory - day));

      dataset.trend_data[niche.niche_id].push({
        date: date.toISOString().split('T')[0],
        value: value,
        type: 'historical'
      });
    }

    // Generate cross-platform metrics
    dataset.cross_platform_metrics[niche.niche_id] = {};

    platforms.forEach(platform => {
      dataset.cross_platform_metrics[niche.niche_id][platform] = {
        demand_score: randomScore(),
        supply_score: randomScore(),
        engagement_score: randomScore(),
        growth_rate: (Math.random() * 0.3) - 0.05 // -5% to +25%
      };
    });
  }

  return dataset;
}

function randomScore() {
  return Math.round(Math.random() * 100) / 100; // 0.00 to 1.00
}
```

## Test Reporting

### Metrics to Track

- **Test Coverage**: Aim for >90% code coverage for critical components
- **Test Success Rate**: Target >99% pass rate in CI
- **Test Execution Time**: Monitor for performance regression
- **Defect Density**: Bugs per 1000 lines of code
- **Test Stability**: Flaky test percentage

### Report Integration

- Daily test summary in Slack
- Test coverage report in PR reviews
- Weekly quality metrics dashboard
- Release readiness report

## Responsible Team

- **QA Lead**:
- **Test Automation Engineer**:
- **Performance Test Engineer**:
- **Security Test Engineer**:
