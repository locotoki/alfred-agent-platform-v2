# Infrastructure Component: Disaster Recovery

*Last Updated: 2025-05-13*
*Owner: Infrastructure Team*
*Status: Active*

## Overview

This document describes the disaster recovery (DR) procedures for the Alfred Agent Platform v2. The disaster recovery plan ensures business continuity by minimizing downtime and data loss in the event of infrastructure failures, data corruption, or other catastrophic events. The procedures outlined here cover backup strategies, recovery processes, high availability configurations, and testing protocols.

## Architecture

The disaster recovery architecture for the Alfred Agent Platform v2 is designed with redundancy and resilience at multiple levels:

```mermaid
graph TB
    subgraph "Primary Region"
        primary_eks[EKS Cluster]
        primary_db[(PostgreSQL Database)]
        primary_redis[(Redis Cache)]
        primary_vector[(Vector Database)]
        primary_s3[Object Storage]
        primary_mon[Monitoring]
    end

    subgraph "Secondary Region"
        secondary_eks[EKS Cluster]
        secondary_db[(PostgreSQL Database)]
        secondary_redis[(Redis Cache)]
        secondary_vector[(Vector Database)]
        secondary_s3[Object Storage]
        secondary_mon[Monitoring]
    end

    subgraph "Backup Services"
        db_backups[(Database Backups)]
        s3_backups[(Object Storage Backups)]
        config_backups[(Config Backups)]
        image_registry[(Container Registry)]
    end

    subgraph "Recovery Automation"
        terraform[Terraform Scripts]
        dr_scripts[DR Scripts]
        monitoring[DR Monitoring]
    end

    primary_db --> |Replication| secondary_db
    primary_s3 --> |Cross-Region Replication| secondary_s3

    primary_db --> |Backup| db_backups
    primary_s3 --> |Backup| s3_backups
    primary_eks --> |Config Backup| config_backups

    terraform --> secondary_eks
    dr_scripts --> secondary_eks
    dr_scripts --> secondary_db
    dr_scripts --> secondary_redis
    dr_scripts --> secondary_vector

    monitoring --> primary_mon
    monitoring --> secondary_mon
```

## Backup Procedures

### Database Backups

#### PostgreSQL Backup

The platform's PostgreSQL databases are backed up using the following strategies:

1. **Daily Full Backups**
   ```bash
   # Daily full backup using pg_dump
   pg_dump -U postgres -d postgres -F c -f /backups/postgres_$(date +\%Y\%m\%d).dump

   # Copy backup to secure storage
   aws s3 cp /backups/postgres_$(date +\%Y\%m\%d).dump s3://alfred-platform-backups/postgres/daily/
   ```

2. **Point-in-Time Recovery Using WAL Archiving**
   ```bash
   # PostgreSQL configuration for WAL archiving
   archive_mode = on
   archive_command = 'test ! -f /archive/%f && cp %p /archive/%f'
   archive_timeout = 60

   # Copy WAL files to secure storage
   aws s3 sync /archive/ s3://alfred-platform-backups/postgres/wal/
   ```

3. **Streaming Replication to Standby Server**
   ```bash
   # Setup primary server for replication
   primary_conninfo = 'host=standby-db port=5432 user=replicator password=secure_password'
   primary_slot_name = 'standby_replication_slot'
   ```

#### Redis Backup

Redis data is persisted using:

1. **RDB Snapshots**
   ```bash
   # Redis configuration for RDB snapshots
   save 900 1       # Save after 900 seconds if at least 1 change
   save 300 10      # Save after 300 seconds if at least 10 changes
   save 60 10000    # Save after 60 seconds if at least 10000 changes

   # Copy RDB files to secure storage
   aws s3 cp /var/lib/redis/dump.rdb s3://alfred-platform-backups/redis/
   ```

2. **AOF (Append-Only File) Persistence**
   ```bash
   # Redis configuration for AOF
   appendonly yes
   appendfsync everysec

   # Copy AOF files to secure storage
   aws s3 cp /var/lib/redis/appendonly.aof s3://alfred-platform-backups/redis/
   ```

#### Vector Database Backup

Qdrant vector database is backed up using:

```bash
# Create a snapshot of all collections
curl -X POST "http://vector-db:6333/snapshots"

# Download the snapshot
curl -X GET "http://vector-db:6333/snapshots/{snapshot_id}" --output /backups/qdrant_snapshot_$(date +\%Y\%m\%d).tar

# Copy snapshot to secure storage
aws s3 cp /backups/qdrant_snapshot_$(date +\%Y\%m\%d).tar s3://alfred-platform-backups/vector-db/
```

### Storage and Configuration Backups

#### Object Storage Backup

S3 buckets are backed up using cross-region replication:

```yaml
# AWS S3 Cross-Region Replication configuration
ReplicationConfiguration:
  Role: arn:aws:iam::account-id:role/s3-replication-role
  Rules:
    - Status: Enabled
      Priority: 1
      DeleteMarkerReplication:
        Status: Enabled
      Destination:
        Bucket: arn:aws:s3:::alfred-platform-backups-secondary-region
        ReplicationTime:
          Status: Enabled
          Time:
            Minutes: 15
        Metrics:
          Status: Enabled
          EventThreshold:
            Minutes: 15
```

#### Container Image Backup

Docker images are backed up by pushing to multiple registries:

```bash
# Push images to secondary registry
for service in alfred-bot architect-api legal-compliance financial-tax mission-control; do
  docker pull ${PRIMARY_REGISTRY}/alfred-platform/${service}:latest
  docker tag ${PRIMARY_REGISTRY}/alfred-platform/${service}:latest ${SECONDARY_REGISTRY}/alfred-platform/${service}:latest
  docker push ${SECONDARY_REGISTRY}/alfred-platform/${service}:latest
done
```

#### Infrastructure Configuration Backup

Terraform state and Kubernetes configurations are backed up:

```bash
# Backup Terraform state
aws s3 sync s3://alfred-platform-terraform-state/ s3://alfred-platform-backups/terraform/

# Backup Kubernetes manifests
kubectl get all --all-namespaces -o yaml > /backups/k8s_all_resources_$(date +\%Y\%m\%d).yaml
kubectl get secrets --all-namespaces -o yaml > /backups/k8s_secrets_$(date +\%Y\%m\%d).yaml
kubectl get configmaps --all-namespaces -o yaml > /backups/k8s_configmaps_$(date +\%Y\%m\%d).yaml

# Copy Kubernetes backups to secure storage
aws s3 cp /backups/k8s_*.yaml s3://alfred-platform-backups/kubernetes/
```

## Recovery Procedures

### Database Recovery

#### PostgreSQL Recovery

1. **Full Backup Recovery**
   ```bash
   # Download the most recent backup
   aws s3 cp s3://alfred-platform-backups/postgres/daily/postgres_20250513.dump /tmp/

   # Restore from backup
   pg_restore -U postgres -d postgres -c /tmp/postgres_20250513.dump
   ```

2. **Point-in-Time Recovery**
   ```bash
   # Create recovery.conf (PostgreSQL <12)
   cat > ${PGDATA}/recovery.conf << EOF
   restore_command = 'aws s3 cp s3://alfred-platform-backups/postgres/wal/%f %p'
   recovery_target_time = '2025-05-13 08:30:00'
   EOF

   # PostgreSQL 12+ configuration
   cat > ${PGDATA}/postgresql.conf << EOF
   restore_command = 'aws s3 cp s3://alfred-platform-backups/postgres/wal/%f %p'
   recovery_target_time = '2025-05-13 08:30:00'
   EOF

   touch ${PGDATA}/recovery.signal

   # Start PostgreSQL
   pg_ctl -D ${PGDATA} start
   ```

3. **Failover to Standby**
   ```bash
   # Promote standby to primary
   pg_ctl promote -D ${PGDATA}

   # Update connection strings in services
   kubectl set env deployment/agent-core DATABASE_URL=postgresql://postgres:password@new-primary-db:5432/postgres
   ```

#### Redis Recovery

1. **RDB Recovery**
   ```bash
   # Download the most recent RDB backup
   aws s3 cp s3://alfred-platform-backups/redis/dump.rdb /tmp/

   # Stop Redis
   systemctl stop redis

   # Replace the RDB file
   cp /tmp/dump.rdb /var/lib/redis/dump.rdb
   chown redis:redis /var/lib/redis/dump.rdb

   # Start Redis
   systemctl start redis
   ```

2. **AOF Recovery**
   ```bash
   # Download the most recent AOF backup
   aws s3 cp s3://alfred-platform-backups/redis/appendonly.aof /tmp/

   # Stop Redis
   systemctl stop redis

   # Replace the AOF file
   cp /tmp/appendonly.aof /var/lib/redis/appendonly.aof
   chown redis:redis /var/lib/redis/appendonly.aof

   # Start Redis
   systemctl start redis
   ```

#### Vector Database Recovery

```bash
# Download the most recent snapshot
aws s3 cp s3://alfred-platform-backups/vector-db/qdrant_snapshot_20250513.tar /tmp/

# Upload the snapshot
curl -X PUT "http://vector-db:6333/snapshots/20250513" \
  -H "Content-Type: multipart/form-data" \
  --form "snapshot=@/tmp/qdrant_snapshot_20250513.tar"

# Recover from snapshot
curl -X POST "http://vector-db:6333/snapshots/20250513/recover"
```

### Application and Infrastructure Recovery

#### Kubernetes Cluster Recovery

```bash
# Create a new Kubernetes cluster
terraform apply -var-file=prod.tfvars -target=module.eks

# Apply critical configurations
kubectl apply -f /backups/k8s_namespaces.yaml
kubectl apply -f /backups/k8s_secrets.yaml
kubectl apply -f /backups/k8s_configmaps.yaml

# Deploy core infrastructure services
kubectl apply -f k8s/infrastructure/

# Deploy application services
kubectl apply -f k8s/applications/
```

#### Container Image Recovery

```bash
# Pull images from backup registry
for service in alfred-bot architect-api legal-compliance financial-tax mission-control; do
  docker pull ${SECONDARY_REGISTRY}/alfred-platform/${service}:latest
  docker tag ${SECONDARY_REGISTRY}/alfred-platform/${service}:latest ${PRIMARY_REGISTRY}/alfred-platform/${service}:latest
  docker push ${PRIMARY_REGISTRY}/alfred-platform/${service}:latest
done
```

#### Object Storage Recovery

```bash
# Restore from cross-region replication
aws s3 sync s3://alfred-platform-backups-secondary-region/ s3://alfred-platform-primary/
```

## Disaster Recovery Plan

### Disaster Classification

Disasters are classified into four levels based on severity and impact:

| Level | Description | Example | RTO | RPO |
|-------|-------------|---------|-----|-----|
| 1 | Minor incident | Single pod failure | < 5 minutes | 0 |
| 2 | Service disruption | Database unavailability | < 30 minutes | < 5 minutes |
| 3 | Major outage | Region failure | < 4 hours | < 15 minutes |
| 4 | Catastrophic failure | Multi-region failure | < 24 hours | < 1 hour |

### Recovery Time Objectives (RTO)

The target recovery times for different components:

| Component | Level 1 | Level 2 | Level 3 | Level 4 |
|-----------|---------|---------|---------|---------|
| API Services | 5 min | 15 min | 1 hour | 4 hours |
| Databases | 5 min | 30 min | 2 hours | 6 hours |
| Storage | 5 min | 15 min | 2 hours | 8 hours |
| Full Platform | 15 min | 1 hour | 4 hours | 24 hours |

### Recovery Point Objectives (RPO)

The acceptable data loss timeframes:

| Component | Level 1 | Level 2 | Level 3 | Level 4 |
|-----------|---------|---------|---------|---------|
| PostgreSQL | 0 | < 5 min | < 15 min | < 1 hour |
| Redis | 0 | < 5 min | < 30 min | < 2 hours |
| Vector DB | 0 | < 10 min | < 1 hour | < 4 hours |
| Object Storage | 0 | 0 | < 15 min | < 1 hour |

### Disaster Recovery Team

The DR response team structure:

| Role | Responsibility | Primary Contact | Secondary Contact |
|------|----------------|-----------------|-------------------|
| DR Coordinator | Overall coordination of recovery efforts | [DR Coordinator] | [Backup Coordinator] |
| Database Admin | Database recovery operations | [DBA Lead] | [DBA Backup] |
| Infrastructure Engineer | Infrastructure recovery | [Infra Lead] | [Infra Backup] |
| Application Engineer | Application recovery and validation | [App Lead] | [App Backup] |
| Security Officer | Security validation during recovery | [Security Lead] | [Security Backup] |

### Communication Plan

Communication protocol during disaster recovery:

1. **Initial Alert**
   - Alert sent via PagerDuty to DR Team
   - Conference bridge automatically created
   - Status page updated automatically

2. **Regular Updates**
   - Updates provided every 30 minutes (minimum)
   - Status page updated with progress
   - Stakeholders notified via email

3. **Resolution Communication**
   - All-clear notification to all stakeholders
   - Incident report within 24 hours
   - Post-mortem meeting scheduled

## Disaster Recovery Scenarios

### Scenario 1: Single Availability Zone Failure

Steps to recover from a single AZ failure:

1. **Assessment (5 min)**
   - Confirm AZ failure via AWS console and monitoring alerts
   - Convene DR team on communication channel

2. **Containment (5-10 min)**
   - Update Kubernetes node affinity rules to avoid failed AZ
   ```yaml
   affinity:
     nodeAffinity:
       requiredDuringSchedulingIgnoredDuringExecution:
         nodeSelectorTerms:
         - matchExpressions:
           - key: topology.kubernetes.io/zone
             operator: NotIn
             values:
             - us-east-1a  # Failed AZ
   ```

3. **Recovery (10-15 min)**
   - Scale up nodes in remaining AZs
   ```bash
   eksctl scale nodegroup --cluster=alfred-platform-prod --name=general --nodes=6
   ```
   - Verify services are rescheduled
   ```bash
   kubectl get pods -o wide | grep -v Running
   ```

4. **Validation (5 min)**
   - Run health check tests
   ```bash
   ./scripts/health-check.sh --environment=production
   ```

### Scenario 2: Database Failure

Steps to recover from a database failure:

1. **Assessment (5 min)**
   - Confirm database failure through monitoring
   - Determine if it's a connection issue or data corruption

2. **Mitigation (5-10 min)**
   - If connection issue:
     ```bash
     # Restart database if needed
     kubectl rollout restart statefulset db-postgres -n alfred-platform-prod
     ```
   - If data corruption, proceed to recovery steps

3. **Recovery (15-30 min)**
   - Promote standby to primary (if available)
     ```bash
     # On standby server
     pg_ctl promote -D ${PGDATA}

     # Update connection strings
     kubectl set env deployment -l app=alfred-platform DATABASE_URL=postgresql://postgres:password@db-postgres-standby:5432/postgres
     ```
   - Or restore from backup
     ```bash
     # Download and restore backup
     aws s3 cp s3://alfred-platform-backups/postgres/daily/postgres_latest.dump /tmp/
     pg_restore -U postgres -d postgres -c /tmp/postgres_latest.dump
     ```

4. **Validation (10 min)**
   - Verify database connectivity
   ```bash
   kubectl exec -it deployment/agent-core -- python -c "from app.db import get_db; print(get_db().execute('SELECT 1').fetchone())"
   ```
   - Run database integrity checks
   ```bash
   kubectl exec -it statefulset/db-postgres -- psql -U postgres -c "SELECT count(*) FROM tasks;"
   ```

### Scenario 3: Full Region Failure

Steps to recover from a complete region failure:

1. **Assessment (10 min)**
   - Confirm region failure and impact scope
   - Activate DR team and communication plan

2. **Failover Initiation (15 min)**
   - Update DNS to point to the secondary region
   ```bash
   aws route53 change-resource-record-sets \
     --hosted-zone-id ${HOSTED_ZONE_ID} \
     --change-batch file://dns-failover.json
   ```
   - Promote secondary database to primary
   ```bash
   # On secondary database
   pg_ctl promote -D ${PGDATA}
   ```

3. **Recovery (1-2 hours)**
   - Scale up resources in secondary region
   ```bash
   terraform apply -var-file=dr.tfvars -target=module.eks_secondary_region
   ```
   - Verify database replication status
   ```bash
   kubectl exec -it statefulset/db-postgres-secondary -- psql -U postgres -c "SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(), pg_last_xact_replay_timestamp();"
   ```
   - Deploy application components
   ```bash
   kubectl apply -f k8s/applications/ --context=secondary-cluster
   ```

4. **Validation (30 min)**
   - Run comprehensive health checks
   ```bash
   ./scripts/dr-validation.sh --environment=production --region=secondary
   ```
   - Verify end-to-end functionality
   ```bash
   ./scripts/e2e-tests.sh --environment=production --region=secondary
   ```

### Scenario 4: Ransomware/Data Corruption

Steps to recover from a ransomware attack or data corruption:

1. **Assessment and Containment (15-30 min)**
   - Identify affected systems and isolate them
   ```bash
   # Isolate affected namespaces
   kubectl label namespace affected-namespace network-policy=isolate
   kubectl apply -f network-policies/isolate.yaml
   ```
   - Shut down affected services
   ```bash
   kubectl scale deployment -l app=affected-service --replicas=0
   ```

2. **Determine Clean State (30 min)**
   - Identify last known good backup
   - Check backup integrity
   ```bash
   aws s3 ls s3://alfred-platform-backups/postgres/daily/ --recursive
   pg_restore --list /tmp/postgres_20250512.dump
   ```

3. **Recovery (2-4 hours)**
   - Restore databases from clean backups
   - Deploy clean container images
   ```bash
   # Pull known clean images
   docker pull ${REGISTRY}/alfred-platform/${service}:${CLEAN_TAG}

   # Update deployments to use clean images
   kubectl set image deployment/${service} ${service}=${REGISTRY}/alfred-platform/${service}:${CLEAN_TAG}
   ```
   - Restore configurations from backup
   ```bash
   kubectl apply -f /backups/k8s_configmaps_clean.yaml
   ```

4. **Security Validation (1 hour)**
   - Run security scans on restored systems
   ```bash
   ./scripts/security-scan.sh --environment=production
   ```
   - Validate access controls
   ```bash
   kubectl auth can-i --list --namespace=alfred-platform-prod
   ```

## High Availability Configuration

### Multi-AZ Deployment

Services are distributed across multiple Availability Zones:

```yaml
# Pod anti-affinity to spread across AZs
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - alfred-platform
        topologyKey: topology.kubernetes.io/zone
```

### Database High Availability

PostgreSQL high availability configuration:

```yaml
# PostgreSQL StatefulSet with PodAntiAffinity
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: alfred-platform-prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - postgres
            topologyKey: topology.kubernetes.io/zone
```

Redis high availability using Redis Sentinel:

```yaml
# Redis Sentinel configuration
sentinel monitor mymaster redis-master.alfred-platform-prod.svc.cluster.local 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
```

### Load Balancer Configuration

Load balancers are configured for high availability:

```yaml
# AWS Network Load Balancer configuration
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: alfred-platform-prod
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
spec:
  type: LoadBalancer
  ports:
  - port: 443
    targetPort: 8080
  selector:
    app: api-gateway
```

## Disaster Recovery Testing

### Testing Schedule

| Test Type | Frequency | Last Test | Next Test |
|-----------|-----------|-----------|-----------|
| Component Recovery | Monthly | 2025-04-15 | 2025-05-15 |
| Regional Failover | Quarterly | 2025-03-10 | 2025-06-10 |
| Full DR Simulation | Annually | 2025-01-20 | 2026-01-20 |

### Test Procedures

1. **Component Recovery Testing**
   ```bash
   # Schedule test window in non-peak hours
   # Run database recovery test
   ./scripts/dr-test.sh --component=database --scenario=corruption

   # Run object storage recovery test
   ./scripts/dr-test.sh --component=storage --scenario=deletion
   ```

2. **Regional Failover Testing**
   ```bash
   # Schedule test window with proper notification
   # Execute regional failover test
   ./scripts/dr-test.sh --type=regional-failover --notify=true

   # Validate application functionality in secondary region
   ./scripts/validation-tests.sh --region=secondary

   # Execute failback procedure
   ./scripts/dr-test.sh --type=regional-failback --notify=true
   ```

3. **Full DR Simulation**
   ```bash
   # Schedule comprehensive DR simulation
   # Simulate major outage scenario
   ./scripts/dr-simulation.sh --scenario=major-outage

   # Execute full recovery workflow
   ./scripts/dr-recovery.sh --scenario=major-outage

   # Document findings and improvement areas
   ./scripts/dr-report.sh > dr-simulation-report-$(date +\%Y\%m\%d).md
   ```

### Test Validation Criteria

| Component | Validation Criteria | Success Threshold |
|-----------|---------------------|-------------------|
| Database Recovery | Data integrity check | 100% |
| Database Recovery | RTO compliance | < 30 minutes |
| Regional Failover | Service availability | > 99.9% |
| Regional Failover | Data consistency | 100% |
| Full DR Simulation | Process compliance | > 95% |
| Full DR Simulation | RTO/RPO compliance | 100% |

## Related Components

- [Database Infrastructure](../database/database-infrastructure.md)
- [Kubernetes Deployment](../containerization/kubernetes-deployment.md)
- [Infrastructure Security](../security/infrastructure-security.md)
- [Monitoring Infrastructure](../monitoring/monitoring-infrastructure.md)
- [CI/CD Pipeline Infrastructure](../ci-cd/ci-cd-pipeline-infrastructure.md)

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2025-05-13 | Initial version | Infrastructure Team |

## References

- [AWS Disaster Recovery Whitepaper](https://aws.amazon.com/blogs/architecture/disaster-recovery-dr-architecture-on-aws-part-i-strategies-for-recovery-in-the-cloud/)
- [PostgreSQL Backup and Recovery Documentation](https://www.postgresql.org/docs/current/backup.html)
- [Kubernetes StatefulSet Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Redis High Availability Documentation](https://redis.io/topics/sentinel)
- [NIST Contingency Planning Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-34r1.pdf)
