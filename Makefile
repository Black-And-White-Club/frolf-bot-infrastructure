# Frolf Bot Local Development Makefile

.PHONY: help bootstrap install-tools fix-ansible-k8s install-deps setup-all setup-k8s setup-storage setup-monitoring setup-argocd deploy-app clean nuclear-clean status dev dev-down build-images deploy-argocd urls

help: ## Show this help message
	@echo "Frolf Bot Development Commands:"
	@echo ""
	@echo "🚀 One-Command Setups:"
	@echo "  bootstrap            🔥 Complete setup: infrastructure + GitOps + ready to go!"
	@echo "  dev                  Start Tilt (infrastructure + apps with live reload)"
	@echo ""
	@echo "📋 Step-by-Step Workflows:"
	@echo "  setup-all            Ansible setup (infrastructure only)"
	@echo "  deploy-app           Traditional deploy (build + deploy once)"
	@echo ""
	@echo "📋 Individual Commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

bootstrap: ## 🔥 Complete setup: infrastructure + GitOps + ready for development
	@echo "🚀 BOOTSTRAPPING FROLF BOT INFRASTRUCTURE"
	@echo "========================================"
	@echo "This will set up everything you need:"
	@echo "  ✅ Install required tools (Tilt)"
	@echo "  ✅ Local Kubernetes cluster"
	@echo "  ✅ Storage & monitoring stack"  
	@echo "  ✅ ArgoCD for GitOps"
	@echo "  ✅ Multi-tenant guild ApplicationSet"
	@echo "  ✅ Ready for 'make dev' development"
	@echo ""
	@read -p "Continue? [Y/n] " -n 1 -r; \
	echo ""; \
	if [[ ! $$REPLY =~ ^[Nn]$$ ]]; then \
		echo ""; \
		echo "� Step 1/5: Installing development tools..."; \
		$(MAKE) install-tools; \
		echo ""; \
		echo "📦 Step 2/5: Installing dependencies..."; \
		$(MAKE) install-deps; \
		echo ""; \
		echo "🏗️  Step 3/5: Setting up infrastructure (K8s + monitoring + storage)..."; \
		$(MAKE) setup-all; \
		echo ""; \
		echo "🎯 Step 4/5: Deploying ArgoCD ApplicationSets..."; \
		$(MAKE) deploy-applicationset; \
		echo ""; \
		echo "🏗️  Step 5/5: Building application images..."; \
		$(MAKE) build-images; \
		echo ""; \
		echo "🎉 BOOTSTRAP COMPLETE!"; \
		echo "=================="; \
		echo ""; \
		echo "🎯 What's Ready:"; \
		echo "  ✅ Development tools installed"; \
		echo "  ✅ Infrastructure running"; \
		echo "  ✅ ArgoCD managing GitOps"; \
		echo "  ✅ Multi-tenant guild system active"; \
		echo "  ✅ Application images built"; \
		echo ""; \
		echo "🚀 Next Steps:"; \
		echo "  1. Create a Discord secret:"; \
		echo "     kubectl create secret generic discord-secrets \\"; \
		echo "       --from-literal=token=YOUR_DISCORD_TOKEN -n frolf-bot"; \
		echo ""; \
		echo "  2. Start development:"; \
		echo "     make dev"; \
		echo ""; \
		echo "  3. Create your first guild:"; \
		echo "     make create-guild GUILD_ID=123456789 TIER=free"; \
		echo ""; \
		echo "  4. Check status:"; \
		echo "     make status"; \
		echo "     make urls"; \
		echo ""; \
		echo "🌐 Important URLs:"; \
		echo "  Grafana: http://localhost:30000 (admin/admin)"; \
		echo "  ArgoCD:  http://localhost:30080 (admin/<password>)"; \
		echo ""; \
		echo "🔑 Get ArgoCD password:"; \
		echo "  kubectl -n argocd get secret argocd-initial-admin-secret \\"; \
		echo "    -o jsonpath='{.data.password}' | base64 -d"; \
	else \
		echo "❌ Bootstrap cancelled"; \
	fi

install-tools: ## Install required development tools
	@echo "🔧 Installing development tools..."
	@echo "Checking for required tools..."
	@# Check if Homebrew is installed
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "❌ Homebrew not found. Please install it first:"; \
		echo "   /bin/bash -c \"\$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""; \
		exit 1; \
	fi
	@# Install Python dependencies for Ansible Kubernetes modules
	@echo "📦 Installing Python dependencies for Kubernetes..."
	@pip3 install kubernetes || python3 -m pip install kubernetes || echo "⚠️  Could not install kubernetes python library. You may need to install it manually."
	@# Install Ansible if not present
	@if ! command -v ansible >/dev/null 2>&1; then \
		echo "📦 Installing Ansible..."; \
		brew install ansible; \
	else \
		echo "✅ Ansible already installed"; \
	fi
	@# Install Tilt if not present
	@if ! command -v tilt >/dev/null 2>&1; then \
		echo "📦 Installing Tilt..."; \
		brew install tilt-dev/tap/tilt; \
	else \
		echo "✅ Tilt already installed"; \
	fi
	@# Check for kubectl
	@if ! command -v kubectl >/dev/null 2>&1; then \
		echo "📦 Installing kubectl..."; \
		brew install kubectl; \
	else \
		echo "✅ kubectl already installed"; \
	fi
	@# Check for Docker
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "⚠️  Docker not found. Please install Docker Desktop or Colima:"; \
		echo "   brew install docker colima"; \
		echo "   colima start --kubernetes"; \
	else \
		echo "✅ Docker already installed"; \
	fi
	@# Check for Helm
	@if ! command -v helm >/dev/null 2>&1; then \
		echo "📦 Installing Helm..."; \
		brew install helm; \
	else \
		echo "✅ Helm already installed"; \
	fi
	@echo "✅ Development tools ready!"

fix-ansible-k8s: ## Fix Ansible Kubernetes Python dependency issues
	@echo "🔧 Fixing Ansible Kubernetes dependencies..."
	@echo "Installing kubernetes Python library..."
	@# Try different approaches to install the kubernetes library
	@pip3 install kubernetes --break-system-packages 2>/dev/null || \
		python3 -m pip install kubernetes --break-system-packages 2>/dev/null || \
		pip3 install kubernetes 2>/dev/null || \
		python3 -m pip install kubernetes 2>/dev/null || \
		brew install python-kubernetes 2>/dev/null || \
		echo "❌ Could not install kubernetes library. Try manually: pip3 install kubernetes"
	@echo "Installing additional Ansible dependencies..."
	@pip3 install pyyaml --break-system-packages 2>/dev/null || \
		python3 -m pip install pyyaml --break-system-packages 2>/dev/null || \
		pip3 install pyyaml 2>/dev/null || \
		python3 -m pip install pyyaml 2>/dev/null || \
		echo "⚠️  Could not install pyyaml"
	@echo "✅ Kubernetes dependencies should be fixed. Try running bootstrap again."

install-deps: ## Install Ansible dependencies
	@echo "📦 Installing Ansible dependencies..."
	ansible-galaxy collection install -r ansible/requirements.yml

setup-all: install-deps ## Setup complete local development environment
	@echo "🚀 Setting up complete local development environment..."
	cd ansible && ansible-playbook site.yml

setup-k8s: install-deps ## Setup basic Kubernetes environment
	@echo "🎯 Setting up Kubernetes environment..."
	cd ansible && ansible-playbook setup-local-k8s.yml

setup-storage: ## Setup local storage
	@echo "💾 Setting up local storage..."
	cd ansible && ansible-playbook setup-storage.yml

setup-monitoring: ## Setup monitoring stack
	@echo "📊 Setting up monitoring stack..."
	cd ansible && ansible-playbook setup-monitoring.yml

setup-argocd: ## Setup ArgoCD
	@echo "🔄 Setting up ArgoCD..."
	cd ansible && ansible-playbook setup-argocd.yml

dev: ## Start Tilt development environment (live reload)
	@echo "🚀 Starting Tilt development environment..."
	@# Check if Tilt is installed
	@if ! command -v tilt >/dev/null 2>&1; then \
		echo "❌ Tilt not found. Run 'make bootstrap' or 'make install-tools' first."; \
		exit 1; \
	fi
	@echo "This will setup infrastructure + your apps with live reload"
	@echo ""
	@echo "⚠️  Make sure to create Discord secret first:"
	@echo "   kubectl create secret generic discord-secrets --from-literal=token=YOUR_DISCORD_TOKEN -n frolf-bot"
	@echo ""
	@read -p "Press Enter to continue or Ctrl+C to cancel..."
	tilt up

dev-down: ## Stop Tilt development environment
	@echo "🛑 Stopping Tilt development environment..."
	tilt down

build-images: ## Build Docker images for your applications
	@echo "🏗️  Building application images..."
	docker build -t frolf-bot-backend:latest /Users/jace/Documents/GitHub/frolf-bot
	docker build -t frolf-bot-discord:latest /Users/jace/Documents/GitHub/discord-frolf-bot
	@echo "✅ Images built successfully!"

deploy-app: build-images ## Build images and deploy Frolf Bot application
	@echo "🚀 Deploying Frolf Bot application..."
	@echo "⚠️  Make sure to set your Discord token first:"
	@echo "   kubectl create secret generic discord-secrets --from-literal=token=YOUR_DISCORD_TOKEN -n frolf-bot"
	@echo ""
	cd ansible && ansible-playbook deploy-frolf-bot.yml
	kubectl apply -f frolf-bot-app-manifests/

deploy-argocd: ## Deploy using ArgoCD ApplicationSets
	@echo "🎯 Deploying with ArgoCD..."
	kubectl apply -f argocd-applications/

status: ## Check deployment status
	@echo "📋 Deployment Status:"
	@echo ""
	@echo "Namespaces:"
	@kubectl get namespaces | grep -E "(frolf-bot|nats|postgres|observability|argocd)"
	@echo ""
	@echo "Pods in frolf-bot namespace:"
	@kubectl get pods -n frolf-bot 2>/dev/null || echo "No frolf-bot namespace found"
	@echo ""
	@echo "Infrastructure pods:"
	@echo "NATS:"
	@kubectl get pods -n nats 2>/dev/null || echo "No nats namespace found"
	@echo "PostgreSQL:"
	@kubectl get pods -n postgres 2>/dev/null || echo "No postgres namespace found"
	@echo "Observability:"
	@kubectl get pods -n observability 2>/dev/null || echo "No observability namespace found"
	@echo ""
	@echo "Services in frolf-bot namespace:"
	@kubectl get svc -n frolf-bot 2>/dev/null || echo "No frolf-bot services found"
	@echo ""
	@echo "ArgoCD Applications:"
	@kubectl get applications -n argocd 2>/dev/null || echo "ArgoCD not installed or no applications"

clean: ## Clean up all resources
	@echo "🧹 Cleaning up resources..."
	@read -p "This will delete all resources. Are you sure? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "🗑️  Removing all namespaces..."; \
		kubectl delete namespace frolf-bot monitoring observability argocd nats postgres --ignore-not-found=true; \
		echo "🗑️  Uninstalling Helm releases..."; \
		helm uninstall prometheus -n monitoring --ignore-not-found || true; \
		helm uninstall loki -n monitoring --ignore-not-found || true; \
		helm uninstall my-grafana -n observability --ignore-not-found || true; \
		helm uninstall my-prometheus -n observability --ignore-not-found || true; \
		helm uninstall my-tempo -n observability --ignore-not-found || true; \
		helm uninstall alloy -n observability --ignore-not-found || true; \
		helm uninstall argocd -n argocd --ignore-not-found || true; \
		helm uninstall my-postgresql -n postgres --ignore-not-found || true; \
		helm uninstall my-nats -n nats --ignore-not-found || true; \
		echo "🗑️  Cleaning up any remaining resources..."; \
		kubectl delete pvc --all --all-namespaces --ignore-not-found=true || true; \
		echo "✅ Cleanup complete - fresh slate ready!"; \
		echo ""; \
		echo "🚀 Now run: make bootstrap"; \
	else \
		echo "❌ Cleanup cancelled"; \
	fi

nuclear-clean: ## 🔥 NUCLEAR: Reset entire Colima cluster (removes everything)
	@echo "💥 NUCLEAR CLEANUP - This will reset your entire Kubernetes cluster!"
	@echo "⚠️  This will:"
	@echo "   - Stop Colima"
	@echo "   - Delete the entire VM"
	@echo "   - Start fresh with new cluster"
	@echo ""
	@read -p "Are you ABSOLUTELY sure? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "💥 Stopping Colima..."; \
		colima stop || true; \
		echo "💥 Deleting Colima VM..."; \
		colima delete --force || true; \
		echo "🚀 Starting fresh Colima with Kubernetes..."; \
		colima start --kubernetes --cpu 4 --memory 8 --disk 50; \
		echo "✅ Fresh Kubernetes cluster ready!"; \
		echo ""; \
		echo "🚀 Now run: make bootstrap"; \
	else \
		echo "❌ Nuclear cleanup cancelled"; \
	fi

urls: ## Show important URLs
	@echo "🌐 Important URLs:"
	@echo ""
	@echo "Grafana:    http://localhost:30000 (admin/admin)"
	@echo "ArgoCD:     http://localhost:30080 (admin/<get-password>)"
	@echo ""
	@echo "Get ArgoCD password:"
	@echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"

# Multi-tenant guild management (Ansible + ArgoCD)
create-guild: ## Create new guild via GitOps (usage: make create-guild GUILD_ID=123456 TIER=free)
	@if [ -z "$(GUILD_ID)" ]; then \
		echo "❌ GUILD_ID is required. Usage: make create-guild GUILD_ID=123456 TIER=free"; \
		exit 1; \
	fi
	@echo "🎯 Creating guild $(GUILD_ID) with tier $(TIER)..."
	@echo "Using Ansible for configuration management..."
	@ansible-playbook ansible/guild-management.yml \
		-e action=create \
		-e guild_id=$(GUILD_ID) \
		-e tier=$(TIER) \
		-e auto_commit=true
	@echo ""
	@echo "✅ Guild configuration created and committed!"
	@echo "🔄 ArgoCD will automatically detect and deploy the guild"

delete-guild: ## Delete guild via GitOps (usage: make delete-guild GUILD_ID=123456)
	@if [ -z "$(GUILD_ID)" ]; then \
		echo "❌ GUILD_ID is required. Usage: make delete-guild GUILD_ID=123456"; \
		exit 1; \
	fi
	@echo "🗑️  Deleting guild $(GUILD_ID)..."
	@ansible-playbook ansible/guild-management.yml \
		-e action=delete \
		-e guild_id=$(GUILD_ID) \
		-e auto_commit=true
	@echo ""
	@echo "✅ Guild configuration removed and committed!"
	@echo "🔄 ArgoCD will automatically clean up the guild resources"

list-guilds: ## List all configured guilds
	@echo "📋 Configured Discord Guilds:"
	@ansible-playbook ansible/guild-management.yml -e action=list
	@echo ""
	@echo "📊 Deployed Guilds (ArgoCD Status):"
	@kubectl get applications -n argocd -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status" | grep guild- || echo "  No deployed guilds found"

guild-status: ## Show status for specific guild (usage: make guild-status GUILD_ID=123456)
	@if [ -z "$(GUILD_ID)" ]; then \
		echo "❌ GUILD_ID is required. Usage: make guild-status GUILD_ID=123456"; \
		exit 1; \
	fi
	@echo "📊 Guild $(GUILD_ID) Configuration:"
	@ansible-playbook ansible/guild-management.yml \
		-e action=status \
		-e guild_id=$(GUILD_ID)
	@echo ""
	@echo "📊 Guild $(GUILD_ID) ArgoCD & Kubernetes Status:"
	@echo "ArgoCD Application:"
	@kubectl get application guild-$(GUILD_ID) -n argocd -o yaml 2>/dev/null | \
		grep -E "(sync|health):" | head -4 | sed 's/^/  /' || echo "  ❌ ArgoCD application not found"
	@echo "Kubernetes Resources:"
	@kubectl get pods -n guild-$(GUILD_ID) 2>/dev/null | sed 's/^/  /' || echo "  ❌ Guild namespace not found"

# ArgoCD Management (Pure GitOps)
argocd-sync-guilds: ## Sync all guild applications in ArgoCD
	@echo "🔄 Syncing all guild applications in ArgoCD..."
	@kubectl get applications -n argocd -o name | grep guild- | \
		xargs -I {} kubectl patch {} -n argocd --type merge -p '{"operation":{"sync":{}}}' 2>/dev/null || \
		echo "No guild applications found to sync"
	@echo "✅ Sync initiated for all guild applications"

deploy-applicationset: ## Deploy the guild ApplicationSet to ArgoCD
	@echo "🚀 Deploying guild ApplicationSet to ArgoCD..."
	@kubectl apply -f argocd-applications/frolf-bot-project.yaml
	@kubectl apply -f argocd-applications/guild-applicationset.yaml
	@echo "✅ ApplicationSet deployed!"
	@echo ""
	@echo "🎯 Perfect GitOps Setup:"
	@echo "   📋 Ansible: Manages infrastructure & guild config files"
	@echo "   🔄 ArgoCD: Deploys & syncs applications from git"
	@echo "   🎮 Best of both worlds!"
