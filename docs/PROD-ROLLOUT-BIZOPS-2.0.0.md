# BizOps 2.0.0 – Production Roll-out (deferred)

## Prerequisites
* kube-context **prod** configured by Infra
* Slack CLI authenticated

## Commands
```bash
helm upgrade --install bizops ./charts/alfred \
    --namespace prod \
    -f charts/alfred/values-bizops-prod.yaml

pytest -m "e2e and bizops" \
       --base-url=https://prod.alfred.local \
       --junitxml=artifacts/bizops_prod_smoke.xml

slack-cli chat send "#releases" "🎉 BizOps 2.0.0 now live in prod"
```

## Container Details
- **Image**: ghcr.io/locotoki/agent_bizops:2.0.0
- **Release**: v0.9.0
- **Epic**: SC-241 Agent Consolidation

## Components Deployed
- Agent BizOps service with static workflows
- Prometheus metrics and ServiceMonitor
- SLA alerts and recording rules
- Production secrets configuration

## Breaking Changes
**Environment Variable Migration Required:**
- `LEGAL_COMPLIANCE_API_KEY` → `BIZOPS_LEGAL_API_KEY`
- `FINANCIAL_TAX_API_KEY` → `BIZOPS_FINANCE_API_KEY`
- `ALFRED_DATABASE_URL` → `BIZOPS_DATABASE_URL`
- `ALFRED_REDIS_URL` → `BIZOPS_REDIS_URL`

## Post-Deployment Verification
1. Health check: `curl https://prod.alfred.local/agent-bizops/health`
2. Metrics check: `curl https://prod.alfred.local/agent-bizops/metrics`
3. Workflow verification: Confirm finance and legal workflows active
4. Legacy env var rejection: Verify hard-fail behavior

## Rollback Plan
```bash
helm rollback bizops -n prod
```

Ready for execution once production infrastructure access is provided.
EOF < /dev/null
