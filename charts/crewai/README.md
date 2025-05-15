# CrewAI Helm Chart

This Helm chart deploys the CrewAI service to a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.16+
- Helm 3.1+
- A Kubernetes secret containing the A2A JWT token

## Installing the Chart

To install the chart with the release name `crewai`:

```bash
helm install crewai ./charts/crewai
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` | Number of replicas |
| image.repository | string | `ghcr.io/locotoki/alfred-agent-platform-v2/crewai` | Image repository |
| image.pullPolicy | string | `IfNotPresent` | Image pull policy |
| image.tag | string | `latest` | Image tag |
| serviceAccount.create | bool | `true` | Create service account |
| serviceAccount.name | string | `crewai-service-account` | Service account name |
| service.type | string | `ClusterIP` | Service type |
| service.port | int | `8080` | Service port |
| crewai.endpoint | string | `https://crewai.prod.internal` | CrewAI service endpoint |
| crewai.auth.audience | string | `https://crewai.prod.internal` | CrewAI authentication audience |
| crewai.auth.token | string | `""` | CrewAI authentication token (should be set via CI/CD) |
| resources | object | `{}` | Resource limits and requests |
| autoscaling.enabled | bool | `true` | Enable autoscaling |
| autoscaling.minReplicas | int | `1` | Minimum replicas |
| autoscaling.maxReplicas | int | `5` | Maximum replicas |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilization |
| autoscaling.targetMemoryUtilizationPercentage | int | `80` | Target memory utilization |
| env | list | `[]` | Environment variables |
| secrets.crewaiA2aToken.name | string | `crewai-a2a-token` | Name of the secret for the A2A token |
| secrets.crewaiA2aToken.key | string | `token` | Key in the secret for the A2A token |

## Upgrading the Chart

To upgrade the chart:

```bash
helm upgrade crewai ./charts/crewai
```

## Uninstalling the Chart

To uninstall/delete the `crewai` deployment:

```bash
helm delete crewai
```

## Security Considerations

- The JWT token is stored as a Kubernetes secret
- The token is mounted as a read-only file in the container
- Service account permissions are limited to what's necessary for the service to function