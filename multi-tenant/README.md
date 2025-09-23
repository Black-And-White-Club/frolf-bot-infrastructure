# Multi-Tenant Guild Management

This directory contains the infrastructure for managing multiple Discord guilds (servers) with different service tiers.

## Architecture: Ansible + ArgoCD (Best Practice)

The multi-tenant setup combines the best of both tools:

### **Ansible** (Infrastructure & Configuration Management)
- **Infrastructure Setup**: Kubernetes, ArgoCD, monitoring stack
- **Guild Lifecycle**: Create/delete guild configuration files
- **Validation**: Ensure configurations are correct before commit
- **Git Operations**: Automated commit and push of config changes

### **ArgoCD** (Application Deployment & GitOps)
- **Application Deployment**: Deploys apps from git automatically
- **Drift Detection**: Ensures actual state matches desired state
- **Multi-tenant Scaling**: ApplicationSet manages N guilds from git files
- **Self-healing**: Automatically fixes configuration drift

### **Why This Combination?**

| Task | ❌ Bash Scripts | ✅ Ansible | ✅ ArgoCD |
|------|----------------|-------------|-----------|
| Infrastructure Setup | Error-prone | Idempotent, declarative | Not designed for this |
| Configuration Management | Manual, brittle | Template-driven, validated | Not designed for this |
| Application Deployment | Manual kubectl | Manual deployment | Automatic, git-driven |
| Scaling | Copy/paste scripts | Parameterized playbooks | ApplicationSet auto-scaling |
| Drift Detection | None | Limited | Built-in |
| Rollback | Manual | Playbook history | Git history |

## Service Tiers

### Free Tier
- 1 replica per service
- Lower resource limits
- Shared infrastructure

### Pro Tier  
- 2 replicas per service (HA)
- Higher resource limits
- Potential for dedicated infrastructure

## GitOps Workflow

### 1. Setup ArgoCD ApplicationSet
```bash
# Deploy the ApplicationSet for automatic guild management
make deploy-applicationset
```

### 2. Create a Guild
```bash
# Create a new guild (adds configuration file and commits to git)
make create-guild GUILD_ID=123456789 TIER=free

# Or manually create the configuration file:
cat > guilds/guild-123456789.yaml << EOF
guild_id: "123456789"
tier: "free"
discord_memory_request: "64Mi"
discord_memory_limit: "128Mi"
discord_cpu_request: "50m"
discord_cpu_limit: "100m"
backend_memory_request: "128Mi"
backend_memory_limit: "256Mi"
backend_cpu_request: "100m"
backend_cpu_limit: "200m"
EOF

# Commit and push
git add guilds/guild-123456789.yaml
git commit -m "Add guild 123456789"
git push
```

### 3. ArgoCD Auto-Deployment
Once committed, ArgoCD will automatically:
- Detect the new guild configuration
- Create namespace `guild-123456789`
- Deploy backend and discord-bot with appropriate resources
- Apply tier-specific configurations

### 4. Management Commands
```bash
# List all configured guilds
make list-guilds

# Check guild status
make guild-status GUILD_ID=123456789

# Delete a guild
make delete-guild GUILD_ID=123456789

# Manually sync all guilds in ArgoCD
make argocd-sync-guilds
```

## Directory Structure

```
multi-tenant/
├── README.md                          # This file
├── guilds/                            # Guild configurations (git-tracked)
│   ├── README.md                      # Guild config template
│   ├── guild-123456789.yaml          # Example free tier guild
│   └── guild-987654321.yaml          # Example pro tier guild
├── kustomize/                         # Kustomize templates
│   ├── base/                          # Base Kubernetes resources
│   │   ├── kustomization.yaml
│   │   └── guild-resources.yaml
│   ├── free/                          # Free tier overlay
│   │   ├── kustomization.yaml
│   │   └── free-resources.yaml
│   └── pro/                           # Pro tier overlay
│       ├── kustomization.yaml
│       └── pro-resources.yaml
└── templates/                         # Legacy templates (deprecated)
    ├── guild-template-free.yaml
    └── guild-template-pro.yaml
```

## Security Considerations

### Discord Token Management
Each guild requires a Discord bot token. Currently handled manually:

1. Create a Discord secret for each guild:
```bash
kubectl create secret generic discord-secrets-123456789 \
  --from-literal=token="YOUR_DISCORD_BOT_TOKEN" \
  -n guild-123456789
```

2. **Future Enhancement**: Integrate with external secret management (Vault, AWS Secrets Manager, etc.)

### Network Isolation
- Each guild gets its own namespace
- Consider NetworkPolicies for additional isolation
- Future: Implement tenant-specific ingress rules

## Scaling Considerations

### Current Limitations
- Single cluster deployment
- Shared infrastructure (DB, NATS)
- Manual secret management

### Future Enhancements
- **Multi-cluster**: Deploy pro tiers to dedicated clusters
- **Database Isolation**: Per-guild databases for pro tier
- **Resource Quotas**: Enforce tier-based limits
- **Monitoring**: Per-guild metrics and alerting
- **Auto-scaling**: HPA based on guild activity

## Migration from Bash Scripts

The legacy bash script approach has been replaced with this GitOps approach:

### Before (Bash)
- Manual kubectl commands
- Script-based deployment
- No version control of guild configs
- Error-prone and not scalable

### After (GitOps)
- Declarative configuration in git
- ArgoCD manages deployment lifecycle
- Automatic sync and drift detection
- Scalable and audit-friendly

### Migration Steps
1. For existing guilds, create configuration files in `guilds/`
2. Deploy the ApplicationSet
3. ArgoCD will reconcile existing resources
4. Remove old bash scripts after validation

## Troubleshooting

### Guild Not Deploying
```bash
# Check ArgoCD application status
kubectl get applications -n argocd | grep guild-

# Check ApplicationSet status
kubectl describe applicationset frolf-bot-guilds -n argocd

# Check guild configuration
make guild-status GUILD_ID=123456789
```

### Resource Issues
```bash
# Check resource usage per guild
kubectl top pods -n guild-123456789

# Check resource limits
kubectl describe deployment discord-bot -n guild-123456789
```

### Sync Issues
```bash
# Force sync all guilds
make argocd-sync-guilds

# Sync specific guild in ArgoCD UI or CLI
argocd app sync guild-123456789
```
