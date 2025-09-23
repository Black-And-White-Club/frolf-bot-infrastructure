# 🚀 Frolf Bot Development - Quick Start Guide

This guide will get you up and running with the Frolf Bot development environment in just a few minutes!

## 📋 Prerequisites

- **macOS** (this guide is optimized for macOS)
- **Homebrew** installed
- **Git** installed
- **Docker** or **Colima** for Kubernetes

## 🏃‍♂️ Quick Start (New Developers)

### 1. **Clone the Infrastructure Repository**
```bash
git clone https://github.com/YOUR_ORG/frolf-bot-infrastructure.git
cd frolf-bot-infrastructure
```

### 2. **Set Up Repositories**

You have several options for getting the required repositories:

#### Option A: Interactive Onboarding (Recommended)
```bash
make onboard    # Guided setup with repository options
```

#### Option B: Auto-detect Existing Repositories
```bash
make auto-detect-repos    # Find repos in common locations
# Follow the suggested link commands
make bootstrap && make dev
```

#### Option C: Link to Existing Local Repositories  
```bash
make link-repos BACKEND_PATH=/path/to/your/frolf-bot \
                DISCORD_PATH=/path/to/your/discord-frolf-bot \
                SHARED_PATH=/path/to/your/frolf-bot-shared
make bootstrap && make dev
```

#### Option D: Clone Fresh Repositories
```bash
# First update repository URLs in Makefile
make clone-repos    # Clone all repositories
make bootstrap      # Complete infrastructure setup  
make dev           # Start development environment
```

That's it! 🎉

## 📂 What Gets Set Up

After running the commands above, you'll have:

```
📁 Parent Directory/
├── 📁 frolf-bot-infrastructure/     (this repo - infrastructure)
├── 📁 frolf-bot/                    (backend API - auto cloned)
├── 📁 discord-frolf-bot/            (Discord bot - auto cloned)
└── 📁 frolf-bot-shared/             (shared libraries - auto cloned)
```

## 🔧 Infrastructure Components

- **🐳 Kubernetes**: Local cluster (via Colima/Docker Desktop)
- **🚀 Tilt**: Live reload development environment  
- **📊 Monitoring**: Grafana, Prometheus, Loki, Tempo
- **💾 Storage**: PostgreSQL database
- **📨 Messaging**: NATS messaging system
- **🔄 GitOps**: ArgoCD for continuous deployment
- **🏗️ Multi-tenant**: Support for multiple Discord guilds

## 🌐 Development URLs

Once running, you can access:

- **Backend API**: http://localhost:8080
- **Grafana**: http://localhost:3000 (admin/admin)  
- **ArgoCD**: http://localhost:30080 (admin/password)
- **PostgreSQL**: localhost:5432
- **NATS**: localhost:4222

## 📋 Available Commands

### Repository Management
```bash
make auto-detect-repos  # Auto-detect repositories in common locations
make clone-repos        # Clone all required repositories
make link-repos         # Link to existing local repositories (see examples)
make check-repos        # Check if all repositories are present  
make update-repos       # Pull latest changes for all repositories
make repo-status        # Show git status for all repositories
```

#### Repository Linking Examples
```bash
# Link individual repositories
make link-repos BACKEND_PATH=/Users/you/Code/frolf-bot
make link-repos DISCORD_PATH=/Users/you/Projects/discord-frolf-bot

# Link all at once
make link-repos \
  BACKEND_PATH=/path/to/frolf-bot \
  DISCORD_PATH=/path/to/discord-frolf-bot \
  SHARED_PATH=/path/to/frolf-bot-shared
```

### Development Environment
```bash
make bootstrap       # Complete setup (first time)
make dev            # Start Tilt development environment
make dev-down       # Stop Tilt
make status         # Check deployment status
make urls           # Show all service URLs
```

### Infrastructure Management
```bash
make setup-all      # Setup infrastructure only
make clean          # Clean up all resources
make nuclear-clean  # Reset entire cluster (nuclear option)
```

### Multi-tenant Guild Management
```bash
make create-guild GUILD_ID=123456789 TIER=free  # Create new guild
make delete-guild GUILD_ID=123456789            # Delete guild  
make list-guilds                                # List all guilds
make guild-status GUILD_ID=123456789            # Show guild status
```

## 🔑 Discord Bot Setup

1. **Create a Discord Application**:
   - Go to https://discord.com/developers/applications
   - Create a new application
   - Go to "Bot" section and create a bot
   - Copy the bot token

2. **Set the Discord Token**:
   ```bash
   kubectl patch secret discord-secrets -n frolf-bot \
     -p '{"data":{"token":"'$(echo -n 'YOUR_DISCORD_TOKEN' | base64)'"}}'
   ```

## 🛠️ Customization

### Environment Variables
```bash
# Skip monitoring stack for lighter development
ENABLE_MONITORING=false make dev

# Use custom repository paths
FROLF_BOT_REPO=/path/to/backend make dev
DISCORD_BOT_REPO=/path/to/discord make dev
SHARED_REPO=/path/to/shared make dev
```

### Repository URLs
Edit the Makefile to update repository URLs:
```makefile
BACKEND_REPO_URL = https://github.com/YOUR_ORG/frolf-bot.git
DISCORD_REPO_URL = https://github.com/YOUR_ORG/discord-frolf-bot.git  
SHARED_REPO_URL = https://github.com/YOUR_ORG/frolf-bot-shared.git
```

## 🔧 Development Workflow

### 1. **Daily Development**
```bash
make dev          # Start development environment
# Edit code in any repository
# Tilt automatically rebuilds and redeploys
```

### 2. **Check Status**
```bash
make status       # See all pods and services
make urls         # Get access URLs
tilt logs         # View application logs
```

### 3. **Update Dependencies**
```bash
make update-repos # Pull latest changes from all repos
```

### 4. **Clean Up**
```bash
make dev-down     # Stop development environment
make clean        # Clean up resources (if needed)
```

## 🐛 Troubleshooting

### Repository Issues
```bash
# Check if all repos are present
make check-repos

# Clone missing repositories
make clone-repos

# Update all repositories  
make update-repos
```

### Infrastructure Issues
```bash
# Check cluster status
make status

# Restart with fresh infrastructure
make clean
make bootstrap

# Nuclear option - reset entire cluster
make nuclear-clean
make bootstrap
```

### Tilt Issues
```bash
# Check Tilt status
tilt get session

# View specific service logs
tilt logs frolf-bot-backend
tilt logs frolf-bot-discord

# Restart Tilt
make dev-down
make dev
```

### Kubernetes Issues
```bash
# Check cluster connection
kubectl get nodes

# Check if Colima is running
colima status

# Restart Colima with Kubernetes
colima delete --force
colima start --kubernetes --cpu 4 --memory 8
```

## 🎯 Next Steps

1. **Explore the Code**: Check out the application repositories that were cloned
2. **Create Your First Guild**: `make create-guild GUILD_ID=123456789 TIER=free`
3. **Monitor Everything**: Visit Grafana at http://localhost:3000
4. **Deploy Changes**: ArgoCD automatically deploys from git commits

## 📚 Learn More

- **Tilt Documentation**: https://docs.tilt.dev/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/
- **NATS Documentation**: https://docs.nats.io/

## 🆘 Getting Help

If you run into issues:

1. Check the troubleshooting section above
2. Run `make status` to see current state
3. Check Tilt logs with `tilt logs`
4. Ask the team for help!

---

**Happy coding! 🚀**
