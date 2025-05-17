# Alert Noise Reduction Guide

## Overview

The Alert Noise Reduction system uses machine learning to automatically identify and suppress low-value alerts, reducing alert fatigue while maintaining critical alert visibility.

## Architecture

```mermaid
graph TD
    A[Alert Stream] --> B[Feature Extraction]
    B --> C[ML Noise Ranker]
    C --> D{Noise Score}
    D -->|> 0.7| E[Suppress Alert]
    D -->|<= 0.7| F[Deliver Alert]
    E --> G[Noise Queue]
    F --> H[Alert Channel]
    
    I[User Feedback] --> J[Training Pipeline]
    J --> K[Model Updates]
    K --> C
```

## Components

### 1. ML Noise Ranker
- **Model**: Random Forest with sentence transformers
- **Features**: Text embeddings, TF-IDF, temporal patterns, historical data
- **Threshold**: 0.7 (configurable)
- **False Negative Target**: < 2%

### 2. Custom Rules Engine
- Service-specific overrides
- YAML-based configuration
- Priority-based evaluation
- Dynamic threshold adjustment

### 3. Feedback Loop
- Thumbs up/down UI
- Implicit signal collection
- Batch feedback support
- Model retraining pipeline

### 4. Alert Snooze API
- Temporary suppression
- TTL-based expiry
- Auto-unsnooze on changes
- Audit trail

## Configuration

### Environment Variables
```bash
# ML Model Configuration
export ML_MODEL_PATH=/models/noise_ranker_v2.pkl
export NOISE_THRESHOLD=0.7
export FALSE_NEGATIVE_TARGET=0.02

# Feature Flags
export ML_RANKING_ENABLED=true
export CUSTOM_RULES_ENABLED=true
export FEEDBACK_COLLECTION_ENABLED=true

# Performance
export RANKER_CACHE_TTL=300
export BATCH_SIZE=100
```

### Custom Rules Example
```yaml
services:
  api-gateway:
    rules:
      - name: "Critical API Alerts"
        priority: 100
        conditions:
          - field: severity
            operator: eq
            value: critical
          - field: labels.endpoint
            operator: in
            value: ["/api/v1/payment", "/api/v1/auth"]
        grouping_keys: ["service", "endpoint", "error_code"]
        similarity_threshold: 0.9
        time_window: 300
        
      - name: "High Frequency Noise"
        priority: 50
        conditions:
          - field: name
            operator: contains
            value: "HealthCheck"
          - field: historical.count_24h
            operator: gt
            value: 100
        grouping_keys: ["service", "instance"]
        similarity_threshold: 0.5
        time_window: 3600
```

## API Usage

### Ranking Alerts
```python
from alfred.alerts.ranker import AlertNoiseRanker

ranker = AlertNoiseRanker(model_path="/models/noise_ranker_v2.pkl")

# Single alert
score = ranker.predict_noise_score(alert, historical_data)
if score > 0.7:
    suppress_alert(alert)

# Batch ranking
ranked_alerts = ranker.rank_alerts(alerts, historical_data)
for alert, score in ranked_alerts:
    if score > 0.7:
        logger.info(f"Suppressing noisy alert: {alert.id}")
```

### Custom Rules
```python
from alfred.alerts.rules import RulesEngine

rules = RulesEngine()
rules.load_rules_from_file("/config/alert_rules.yaml")

# Evaluate alert
result = rules.evaluate_alert(alert)
if result['matching_rule']:
    logger.info(f"Alert matched rule: {result['matching_rule']}")
    group_key = result['group_key']
    threshold = result['similarity_threshold']
```

### Feedback Collection
```javascript
// React component
import { FeedbackPanel } from '@/components/FeedbackPanel';

<FeedbackPanel 
  alertId={alert.id}
  isNoise={alert.noise_score > 0.7}
  onFeedbackComplete={() => refreshAlerts()}
/>
```

### Alert Snoozing
```bash
# Snooze an alert for 1 hour
curl -X PATCH /api/v1/alerts/alert-123/snooze \
  -H "Content-Type: application/json" \
  -d '{"ttl": 3600, "reason": "Known issue, fix in progress"}'

# Unsnooze manually
curl -X DELETE /api/v1/alerts/alert-123/snooze

# Check snooze status
curl /api/v1/alerts/alert-123/snooze
```

## Performance Tuning

### Optimization Strategies

1. **Cache Predictions**
   ```python
   # Redis caching for predictions
   cache_key = f"noise_score:{alert.id}"
   cached_score = redis.get(cache_key)
   if cached_score:
       return float(cached_score)
   ```

2. **Batch Processing**
   ```python
   # Process alerts in batches
   batch_size = 100
   for i in range(0, len(alerts), batch_size):
       batch = alerts[i:i+batch_size]
       scores = ranker.predict_batch(batch)
   ```

3. **Feature Selection**
   ```python
   # Reduce feature dimensionality
   important_features = ranker.get_feature_importance()
   selected_features = important_features[:50]  # Top 50
   ```

### Monitoring

Key metrics to track:
- **noise_reduction_rate**: Percentage of alerts suppressed
- **false_negative_rate**: Critical alerts incorrectly suppressed
- **ranking_latency_p95**: 95th percentile processing time
- **feedback_rate**: User engagement with feedback UI

Example Prometheus queries:
```promql
# Noise reduction effectiveness
rate(suppressed_alerts_total[5m]) / rate(total_alerts[5m])

# False negative monitoring
sum(alert_feedback{type="false_negative"}) / sum(alert_feedback)

# Ranking performance
histogram_quantile(0.95, rate(alert_ranking_duration_bucket[5m]))
```

## Troubleshooting

### Common Issues

1. **High False Negative Rate**
   - Increase noise threshold
   - Add custom rules for critical services
   - Review recent feedback data
   - Retrain model with updated labels

2. **Poor Performance**
   - Enable caching
   - Reduce batch sizes
   - Optimize feature extraction
   - Use feature selection

3. **Incorrect Grouping**
   - Review custom rules
   - Adjust similarity thresholds
   - Check time window settings
   - Validate grouping keys

### Debug Mode
```bash
# Enable debug logging
export ALERT_RANKING_DEBUG=true

# View similarity calculations
export SHOW_SIMILARITY_SCORES=true

# Log feature vectors
export LOG_FEATURE_EXTRACTION=true
```

## Model Training

### Data Preparation
```python
# Collect training data
training_data = []
for alert in historical_alerts:
    features = extract_features(alert)
    label = get_feedback_label(alert)  # 0=signal, 1=noise
    training_data.append((features, label))

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    features, labels, test_size=0.2, stratify=labels
)
```

### Training Pipeline
```python
# Train new model
ranker = AlertNoiseRanker()
ranker.train(X_train, y_train)

# Evaluate
predictions = ranker.predict(X_test)
false_negative_rate = calculate_fnr(y_test, predictions)

if false_negative_rate < 0.02:
    ranker.save_model("/models/noise_ranker_v3.pkl")
```

### A/B Testing
```python
# Gradual rollout
if random.random() < AB_TEST_PERCENTAGE:
    score = new_ranker.predict(alert)
else:
    score = old_ranker.predict(alert)
    
# Track metrics by version
metrics.increment('predictions', tags={'version': ranker_version})
```

## Best Practices

1. **Start Conservative**: Begin with high threshold (0.8+) and gradually decrease
2. **Monitor Continuously**: Track false negatives in real-time
3. **Collect Feedback**: Encourage user feedback for model improvement
4. **Service-Specific Rules**: Use custom rules for critical services
5. **Regular Retraining**: Update model monthly with new feedback
6. **Audit Everything**: Log all suppression decisions for review

## Future Enhancements

- Deep learning models (BERT) for better text understanding
- Multi-label classification for alert categorization
- Automated threshold optimization
- Cross-service correlation analysis
- Predictive alert suppression

## Database Integration

### Loading Alerts from Database

The ML training pipeline now supports loading alert data directly from databases:

```python
# Set database connection
export ALERT_DB_URI="postgresql://user:pass@localhost/alerts"

# Load alerts
from alfred.ml.alert_dataset import load_alert_dataset
dataset = load_alert_dataset(days=30)
```

### Database Schema Requirements

```sql
CREATE TABLE alerts (
    id SERIAL PRIMARY KEY,
    message TEXT NOT NULL,
    severity VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL
);

-- Recommended indexes
CREATE INDEX idx_alerts_created_at ON alerts(created_at);
CREATE INDEX idx_alerts_severity ON alerts(severity);
```

### Automatic PII Stripping

The dataset loader automatically removes PII from alert messages:
- Email addresses → `[EMAIL]`
- IP addresses → `[IP]`
- Phone numbers → `[PHONE]`

### Performance Optimization

For large datasets, configure connection pooling:
```python
from sqlalchemy.pool import QueuePool

engine = create_engine(
    settings.ALERT_DB_URI,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20
)