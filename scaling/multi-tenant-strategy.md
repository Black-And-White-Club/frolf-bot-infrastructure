# Multi-Tenant Scaling Strategy for Frolf Bot

This document outlines the scaling strategy for supporting multiple Discord servers/guilds with different tiers.

## Architecture Overview

### Current Single-Tenant Setup
```
┌─────────────────┐
│   Discord Bot   │
├─────────────────┤
│   PostgreSQL    │
│     NATS        │
│   Monitoring    │
└─────────────────┘
```

### Multi-Tenant Target Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    ArgoCD Management                    │
├─────────────────────────────────────────────────────────┤
│  Tenant 1 (Free)  │  Tenant 2 (Pro)  │  Tenant 3 (Ent) │
│  ┌─────────────┐   │  ┌─────────────┐  │  ┌─────────────┐ │
│  │ Bot Instance│   │  │ Bot Instance│  │  │ Bot Instance│ │
│  │ Shared DB   │   │  │ Dedicated DB│  │  │ Cluster DB  │ │
│  │ Shared NATS │   │  │ Shared NATS │  │  │ Dedicated   │ │
│  └─────────────┘   │  └─────────────┘  │  └─────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Scaling Dimensions

### 1. Horizontal Scaling (Multiple Instances)
- **Namespace-per-tenant**: Each Discord server gets its own namespace
- **Shared services**: Database and NATS can be shared or dedicated based on tier
- **Resource quotas**: Limit resources per tenant/tier

### 2. Vertical Scaling (Resource Allocation)
- **Free Tier**: Minimal resources, shared infrastructure
- **Pro Tier**: Dedicated resources, better SLA
- **Enterprise Tier**: Dedicated cluster, custom configurations

### 3. Cluster Scaling (Multi-Cluster)
- **Regional clusters**: Deploy closer to users
- **Dedicated clusters**: For enterprise customers
- **Backup/DR clusters**: For high availability

## Implementation Strategy

### Phase 1: Namespace-Based Multi-Tenancy
```yaml
# Example: ArgoCD ApplicationSet for multi-tenant deployment
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: frolf-bot-tenants
spec:
  generators:
  - list:
      elements:
      - tenant: "discord-server-123"
        tier: "free"
        resources: "small"
      - tenant: "discord-server-456" 
        tier: "pro"
        resources: "medium"
  template:
    metadata:
      name: "frolf-bot-{{tenant}}"
    spec:
      project: frolf-bot
      source:
        # ... deployment configuration per tenant
      destination:
        namespace: "frolf-bot-{{tenant}}"
```

### Phase 2: Resource-Based Tiers
- **Free**: Shared PostgreSQL, shared NATS, basic monitoring
- **Pro**: Dedicated PostgreSQL, shared NATS, enhanced monitoring
- **Enterprise**: Dedicated everything, advanced features

### Phase 3: Geographic Distribution
- Multiple ArgoCD instances managing regional clusters
- Data locality compliance
- Latency optimization

## ArgoCD Multi-Tenant Patterns

### 1. ApplicationSet per Tier
```
argocd-applications/
├── free-tier-appset.yaml
├── pro-tier-appset.yaml
├── enterprise-tier-appset.yaml
└── shared-services-appset.yaml
```

### 2. Tenant Configuration Management
```
tenants/
├── free/
│   ├── server-123.yaml
│   └── server-456.yaml
├── pro/
│   ├── server-789.yaml
│   └── server-101.yaml
└── enterprise/
    └── server-enterprise.yaml
```

### 3. Hierarchical Resource Management
```yaml
# Base configuration
charts/frolf-bot/values.yaml

# Tier overrides
charts/frolf-bot/values-free.yaml
charts/frolf-bot/values-pro.yaml
charts/frolf-bot/values-enterprise.yaml

# Tenant-specific overrides
tenants/pro/server-789/values.yaml
```

## Resource Management

### Free Tier Limits
```yaml
resources:
  limits:
    memory: 256Mi
    cpu: 200m
  requests:
    memory: 128Mi
    cpu: 100m
```

### Pro Tier Limits
```yaml
resources:
  limits:
    memory: 512Mi
    cpu: 500m
  requests:
    memory: 256Mi
    cpu: 250m
```

### Enterprise Tier
```yaml
resources:
  limits:
    memory: 2Gi
    cpu: 1000m
  requests:
    memory: 1Gi
    cpu: 500m
```

## Database Scaling Strategy

### Shared Database (Free Tier)
- Single PostgreSQL instance
- Database per tenant
- Shared connection pooling

### Dedicated Database (Pro Tier)
- PostgreSQL instance per tenant
- Dedicated resources
- Individual backups

### Clustered Database (Enterprise)
- PostgreSQL cluster with replicas
- High availability
- Cross-region replication

## Monitoring & Observability

### Per-Tenant Metrics
- Namespace-based metric collection
- Tenant-specific dashboards
- Resource usage tracking
- Cost allocation

### Alerting Strategy
- Tier-based alerting rules
- Escalation policies per tier
- SLA monitoring

## Security Considerations

### Network Policies
```yaml
# Tenant isolation
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tenant-isolation
  namespace: frolf-bot-{{tenant}}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tenant: "{{tenant}}"
```

### RBAC per Tenant
- Service accounts per tenant
- Limited permissions scope
- Secret isolation

## Migration Path

### Current → Multi-Tenant
1. **Refactor current setup** to be namespace-aware
2. **Create tenant templates** for ArgoCD ApplicationSets
3. **Implement resource quotas** and limits
4. **Add tenant configuration** management
5. **Test with multiple tenants** in development
6. **Gradual rollout** to production

### Local Testing Strategy
1. **Multiple namespaces** in local cluster
2. **Simulate different tiers** with resource limits
3. **Test ArgoCD ApplicationSets** with tenant generators
4. **Validate isolation** between tenants

## Next Steps for Implementation

1. **Start with namespace-based isolation** in current setup
2. **Create tenant configuration templates**
3. **Implement resource quotas** per namespace
4. **Test multi-tenant ArgoCD ApplicationSets** locally
5. **Plan database partitioning** strategy
6. **Design tenant onboarding** automation
