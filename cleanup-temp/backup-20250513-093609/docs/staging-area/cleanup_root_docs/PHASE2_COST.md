# Phase 2: Cost & Capacity Estimate

This document outlines the projected resource requirements and associated costs for the Advanced Analytics features in Phase 2 of the Social Intelligence service.

## Executive Summary

Phase 2 introduces significant new data processing and storage requirements, particularly for vector search, cross-platform data collection, and ML model training. The estimated monthly cost increase is approximately $3,500, with the most significant contributors being vector storage, compute for ML training, and increased API usage.

## Infrastructure Requirements

### Compute Resources

| Component | Current (Phase 1) | Projected (Phase 2) | Change |
|-----------|-------------------|---------------------|--------|
| **Web Servers** | 2 x 2 vCPU, 8GB RAM | 4 x 2 vCPU, 8GB RAM | +2 instances |
| **ETL Workers** | 1 x 4 vCPU, 16GB RAM | 3 x 4 vCPU, 16GB RAM | +2 instances |
| **ML Training** | None | 2 x 8 vCPU, 32GB RAM, 1 GPU | +2 GPU instances |
| **ML Inference** | None | 2 x 4 vCPU, 16GB RAM | +2 instances |
| **Total vCPUs** | 8 vCPUs | 40 vCPUs | +32 vCPUs |
| **Total RAM** | 32 GB | 160 GB | +128 GB |
| **Total GPUs** | 0 | 2 | +2 GPUs |

### Storage Requirements

| Storage Type | Current (Phase 1) | Projected (Phase 2) | Change |
|--------------|-------------------|---------------------|--------|
| **PostgreSQL** | 100 GB | 500 GB | +400 GB |
| **Vector Store** | None | 250 GB | +250 GB |
| **Object Storage** | 50 GB | 1 TB | +950 GB |
| **ML Model Storage** | None | 25 GB | +25 GB |
| **Log Storage** | 100 GB | 500 GB | +400 GB |
| **Total Storage** | 250 GB | 2.275 TB | +2.025 TB |

### Network Requirements

| Network Resource | Current (Phase 1) | Projected (Phase 2) | Change |
|------------------|-------------------|---------------------|--------|
| **Ingress** | 500 GB/month | 2 TB/month | +1.5 TB/month |
| **Egress** | 1 TB/month | 5 TB/month | +4 TB/month |
| **API Requests** | 5M/month | 25M/month | +20M/month |

## Cost Projections

### Monthly Cloud Infrastructure Costs

| Component | Current Cost | Projected Cost | Change |
|-----------|--------------|----------------|--------|
| **Compute** | $600 | $2,200 | +$1,600 |
| **Storage** | $50 | $450 | +$400 |
| **Network** | $100 | $500 | +$400 |
| **Managed Services** | $300 | $900 | +$600 |
| **Total Infrastructure** | $1,050 | $4,050 | +$3,000 |

### External API Costs

| API | Current Cost | Projected Cost | Change |
|-----|--------------|----------------|--------|
| **YouTube API** | $100 | $200 | +$100 |
| **TikTok API** | $0 | $200 | +$200 |
| **Instagram API** | $0 | $200 | +$200 |
| **Total API Costs** | $100 | $600 | +$500 |

### Total Monthly Cost

| Category | Current | Projected | Change |
|----------|---------|-----------|--------|
| **Infrastructure** | $1,050 | $4,050 | +$3,000 |
| **External APIs** | $100 | $600 | +$500 |
| **Total Monthly** | $1,150 | $4,650 | +$3,500 |

## Cost Optimization Strategies

The following strategies will be implemented to optimize costs:

1. **Auto-scaling**:
   - Scale ML training instances only during training windows
   - Scale inference servers based on request volume
   - Reduce capacity during low-traffic periods (midnight to 6 AM)

2. **Storage Tiering**:
   - Move historical analytics data (>90 days) to cold storage
   - Implement lifecycle policies for object storage
   - Use compression for trend data

3. **Caching**:
   - Cache common analytics queries (TTL: 1 hour)
   - Cache trend charts and visualizations (TTL: 24 hours)
   - Implement shared cache for cross-user insights

4. **API Request Batching**:
   - Batch external API requests to minimize quota usage
   - Implement request de-duplication
   - Cache API responses with appropriate TTLs

## Budget Guardrails

To prevent unexpected cost overruns, we'll implement the following guardrails:

### Cloud Cost Alerts

| Alert | Threshold | Response |
|-------|-----------|----------|
| **Daily Spend** | >$200/day | Investigate anomalies |
| **Weekly Spend** | >$1,200/week | Review usage patterns |
| **Monthly Forecast** | >120% of budget | Implement immediate optimizations |

### Resource Limits

| Resource | Soft Limit | Hard Limit |
|----------|------------|------------|
| **Total vCPUs** | 50 | 75 |
| **API Requests/min** | 1,000 | 1,500 |
| **Vector Searches/min** | 500 | 1,000 |
| **ML Inference/min** | 200 | 400 |

### External API Quotas

| API | Daily Quota | Monthly Budget |
|-----|-------------|----------------|
| **YouTube API** | 50,000 units | $200 |
| **TikTok API** | 10,000 requests | $200 |
| **Instagram API** | 5,000 requests | $200 |

## Capacity Planning

### Peak Load Estimations

| Metric | Current Peak | Projected Peak | Buffer |
|--------|--------------|----------------|--------|
| **Concurrent Users** | 100 | 500 | +20% |
| **Requests per Second** | 50 | 200 | +30% |
| **DB Connections** | 100 | 300 | +25% |
| **Vector Queries per Second** | 0 | 50 | +50% |

### Scaling Thresholds

| Resource | Scale Up | Scale Down |
|----------|----------|------------|
| **Web Servers** | CPU > 70% for 3 min | CPU < 30% for 10 min |
| **ETL Workers** | Queue backlog > 1000 | Queue empty for 5 min |
| **Vector Store** | Query latency > 200ms | - |
| **ML Inference** | GPU utilization > 80% | GPU utilization < 20% |

## Cost-Benefit Analysis

The projected additional cost of $3,500/month is justified by the following benefits:

1. **Revenue Impact**:
   - Expected 30% increase in revenue per user ($75,000/month)
   - 25% increase in user retention
   - 15% increase in conversion rate

2. **Operational Efficiency**:
   - 60% reduction in content planning time
   - 40% reduction in manual trend research
   - 75% faster insight generation

3. **Competitive Advantage**:
   - First-to-market with cross-platform analytics
   - Unique ML-powered recommendation system
   - Superior visualization capabilities

## Monitoring & Optimization

### Cost Monitoring

- Daily cost reports by component
- Weekly trend analysis
- Monthly optimization review
- Quarterly infrastructure review

### Performance Monitoring

- p95 latency by endpoint
- Query execution time by type
- Cache hit/miss ratio
- ML inference time

## Responsible Team

- **Engineering Lead**: 
- **DevOps Engineer**: 
- **ML Engineer**: 
- **Finance Liaison**: