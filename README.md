# Frolf Bot Infrastructure

A scalable, multi-tenant Discord bot infrastructure for disc golf event management with GitOps, monitoring, and live development capabilities.

## 🚀 Quick Start for New Developers

**Just want to get started? Run this:**

```bash
git clone https://github.com/YOUR_ORG/frolf-bot-infrastructure.git
cd frolf-bot-infrastructure
make onboard  # Interactive setup guide
```

**For experienced developers:**

```bash
git clone https://github.com/YOUR_ORG/frolf-bot-infrastructure.git
cd frolf-bot-infrastructure
make clone-repos && make bootstrap && make dev
```

## 🎯 What You Get

- **🐳 Complete Kubernetes Environment**: Local cluster with all services
- **🚀 Live Development**: Tilt-powered hot reload for Go applications  
- **📊 Full Observability**: Grafana, Prometheus, Loki, Tempo monitoring
- **🔄 GitOps Ready**: ArgoCD for continuous deployment
- **🏢 Multi-tenant**: Support for multiple Discord guilds
- **📱 Discord Integration**: Full Discord bot with slash commands
- **🎮 Game Management**: Leaderboards, scoring, user management

## 📂 Architecture Overview

```
.
├── ansible/                      # Ansible playbooks for local setup
│   ├── setup-local-k8s.yml
│   ├── setup-storage.yml
│   ├── setup-monitoring.yml
│   ├── setup-argocd.yml
│   ├── deploy-frolf-bot.yml
│   ├── site.yml
│   ├── requirements.yml
│   ├── inventory
│   └── ansible.cfg
├── argocd-applications/          # ArgoCD ApplicationSets
│   ├── cluster-resources-appset.yaml
│   ├── frolf-bot-appset.yaml
│   └── multisource-appset.yaml
├── charts/                       # Helm values files
│   ├── alloy/
│   ├── loki/
│   ├── nats/
│   ├── nginx/
│   ├── postgres/
│   ├── prometheus/
│   └── tempo/
├── cluster-resources/            # Cluster-wide resources
│   ├── pvc-loki-local-path.yaml
│   └── storage-class-standard.yaml
├── frolf-bot-app-manifests/      # Application manifests
│   ├── ingress.yaml
│   ├── my-nats-service.yaml
│   └── my-postgresql-service.yaml
├── local-dev/                    # Local development overrides
│   └── values/
│       ├── postgres-local.yaml
│       └── nats-local.yaml
├── multi-source-apps/            # Multi-source app definitions
│   ├── loki-app.yaml
│   ├── prometheus-app.yaml
│   └── tempo-app.yaml
├── scaling/                      # Multi-tenant scaling docs
│   └── multi-tenant-strategy.md
├── terraform/                    # Infrastructure as Code
│   ├── modules/
│   │   ├── artifact-registry/
│   │   ├── cloud-engine/
│   │   └── service-account/
│   ├── frolf-bot-project.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   └── versions.tf
├── the-lich-king/                # ArgoCD master ApplicationSet
│   └── lich-king.yaml
├── get_helm.sh                   # Helm installation script
├── Makefile                      # Development commands
├── Tiltfile                      # Tilt configuration for live development
└── README.md
```

## Prerequisites

### For Local Development
- [Docker Desktop](https://www.docker.com/products/docker-desktop) with Kubernetes enabled
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 4.0
- [Tilt](https://docs.tilt.dev/install.html) (optional, for live development)

### For Cloud Production
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [ArgoCD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) (optional)
- Google Cloud SDK (if using GCP)

## Quick Start

### 🔥 One-Command Setup (Recommended)

```bash
# Complete infrastructure setup in one command
make bootstrap
```

This will:
- ✅ Install all dependencies
- ✅ Set up Kubernetes + monitoring + storage  
- ✅ Deploy ArgoCD with GitOps ApplicationSets
- ✅ Build your application images
- ✅ Ready for development and guild management

### 🚀 Start Development

```bash
# Create Discord secret (replace with your token)
kubectl create secret generic discord-secrets \
  --from-literal=token=YOUR_DISCORD_TOKEN -n frolf-bot

# Start live development environment
make dev
```

### 🎮 Create Your First Guild

```bash
# Create a new Discord guild environment
make create-guild GUILD_ID=123456789 TIER=free

# Check status
make guild-status GUILD_ID=123456789
```

### Alternative Approaches

### Option 1: Tilt Development Environment (Skip Bootstrap)

```bash
# Start Colima with Kubernetes
colima start --kubernetes

# Create Discord secret (replace with your token)
kubectl create secret generic discord-secrets --from-literal=token=YOUR_DISCORD_TOKEN -n frolf-bot

# Start everything with live reload
make dev
# This will:
# - Setup infrastructure (PostgreSQL, NATS, monitoring)
# - Build and deploy your apps
# - Enable live reload on code changes
# - Open Tilt dashboard in browser
```

### Option 2: Ansible Setup Only (Infrastructure Focus)

```bash
# Install dependencies
make install-deps

# Setup infrastructure only
make setup-all

# Then manually deploy your apps
make deploy-app
```

### Option 3: Traditional Approach (Learning/Debugging)

```bash
# Use individual Ansible playbooks
cd ansible
ansible-playbook setup-local-k8s.yml
ansible-playbook setup-monitoring.yml
# ... etc
```

The infrastructure uses ArgoCD ApplicationSets for GitOps deployment:

- **the-lich-king**: Master ApplicationSet that manages all charts
- **multisource-appset**: Manages multi-source applications (monitoring stack)
- **cluster-resources-appset**: Manages cluster-wide resources
- **frolf-bot-appset**: Manages the main application components

## Components

### Monitoring Stack
- **Prometheus**: Metrics collection and alerting
- **Loki**: Log aggregation
- **Tempo**: Distributed tracing
- **Alloy**: Telemetry data collection

### Application Infrastructure
- **PostgreSQL**: Database
- **NATS**: Message broker
- **Nginx**: Ingress controller and reverse proxy

### Cloud Infrastructure (Terraform)
- **Service Account**: GCP service account for applications
- **Artifact Registry**: Container image repository
- **Compute Engine**: VM instances for hosting

## Configuration

### Helm Values
Each component has its values file in the `charts/` directory. Customize these files to match your environment requirements.

### ArgoCD Projects
Applications are organized under the `frolf-bot` ArgoCD project. Ensure this project exists in your ArgoCD instance.

### Networking
The infrastructure assumes standard Kubernetes networking. Modify ingress configurations in `frolf-bot-app-manifests/` as needed.

## Multi-Tenant Guild Management

The Frolf Bot supports multi-tenant deployment where each Discord guild (server) gets its own isolated environment with tier-based resource allocation.

### 🏗️ Hybrid Architecture (Best Practice)

**Ansible + ArgoCD** working together:

- **Ansible**: Infrastructure setup, configuration management, guild lifecycle
- **ArgoCD**: Application deployment, GitOps, drift detection, scaling
- **Git**: Single source of truth for all configurations

This approach gives you:
- ✅ **Declarative infrastructure** (Ansible)
- ✅ **GitOps application delivery** (ArgoCD) 
- ✅ **No bash scripts** or manual kubectl commands
- ✅ **Scalable to hundreds of guilds**

### 🎯 Service Tiers

| Tier | Replicas | Resources | Features |
|------|----------|-----------|----------|
| **Free** | 1 | 64Mi-128Mi RAM, 50m-100m CPU | Shared infrastructure |
| **Pro** | 2 (HA) | 128Mi-256Mi RAM, 100m-200m CPU | High availability |

### 🚀 Guild Management

```bash
# Setup ArgoCD ApplicationSet for automatic guild management
make deploy-applicationset

# Create a new guild (GitOps approach)
make create-guild GUILD_ID=123456789 TIER=free

# List all configured guilds
make list-guilds

# Check guild status
make guild-status GUILD_ID=123456789

# Delete a guild
make delete-guild GUILD_ID=123456789

# Force sync all guilds in ArgoCD
make argocd-sync-guilds
```

### 📁 Manual Guild Configuration

You can also manually create guild configurations:

```bash
# Create guild config file
cat > multi-tenant/guilds/guild-123456789.yaml << EOF
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

# Commit and push - ArgoCD will automatically deploy
git add multi-tenant/guilds/guild-123456789.yaml
git commit -m "Add guild 123456789"
git push
```

### 🔐 Security Setup

Each guild needs a Discord bot token:

```bash
# Create Discord secret for the guild
kubectl create secret generic discord-secrets-123456789 \
  --from-literal=token="YOUR_DISCORD_BOT_TOKEN" \
  -n guild-123456789
```

**Note**: Future versions will integrate with external secret management (Vault, AWS Secrets Manager).

### 📖 Detailed Documentation

See [`multi-tenant/README.md`](multi-tenant/README.md) for comprehensive multi-tenant setup, troubleshooting, and advanced configurations.

## Development

### Adding New Components
1. Add Helm values to `charts/`
2. Create app definition in `multi-source-apps/` (for Helm charts) or `frolf-bot-app-manifests/` (for custom manifests)
3. The appropriate ApplicationSet will automatically pick up the new component

### Terraform Modules
Each Terraform module is self-contained in `terraform/modules/`. Add new modules as needed and reference them in `frolf-bot-project.tf`.

## Troubleshooting

### ArgoCD Applications Not Syncing
- Check ApplicationSet logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller`
- Verify Git repository access and file paths
- Ensure ArgoCD project permissions are correct

### Helm Deployments Failing
- Check values files for syntax errors
- Verify chart versions are available
- Check resource quotas and cluster capacity

## Security Considerations

- Review and customize RBAC configurations
- Use secrets management for sensitive data
- Configure network policies as needed
- Regular security updates for base images

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[Add your license here]

## Local Development Tools

### 🎯 Why These Tools?

- **Bash Scripts** ❌ - Primitive, error-prone, hard to maintain
- **Ansible** ✅ - Declarative, idempotent, reusable, great for infrastructure
- **Tilt** ✅ - Perfect for active development, live reloading, visual feedback
- **Makefile** ✅ - Simple interface, consistent commands

### 🚀 Development Workflow

1. **Active Development**: Use Tilt (`make dev`) - **Recommended for you!**
   - Live reload on code changes
   - Visual dashboard
   - Complete stack in one command

2. **Infrastructure Only**: Use Ansible (`make setup-all`) 
   - When you only need infrastructure
   - Production-like setup

3. **Production Deploy**: Use ArgoCD ApplicationSets
   - Real production deployments
   - Git-based workflow

### 📋 Available Commands

```bash
make help                # Show all available commands
make setup-all          # Complete environment setup
make status             # Check deployment status
make clean              # Clean up everything
make urls               # Show service URLs
```
