# Frolf Bot Local Development Makefile

.PHONY: help bootstrap install-tools fix-ansible-k8s install-deps setup-all setup-k8s setup-storage setup-monitoring setup-argocd deploy-app clean nuclear-clean status dev dev-down build-images deploy-argocd urls clone-repos check-repos update-repos verify-setup onboard link-repos

help: ## Show this help message
	@echo "Frolf Bot Development Commands:"
	@echo ""
	@echo "🎮 New Developer? Start Here:"
	@echo "  onboard              🎮 Interactive setup guide for new developers"
	@echo ""
	@echo "🚀 Quick Start (Experienced):"
	@echo "  verify-setup         🔍 Verify your development environment"
	@echo "  clone-repos          📂 Clone all required repositories" 
	@echo "  link-repos           🔗 Link to existing local repositories"
	@echo "  auto-detect-repos    🔍 Auto-detect repositories in common locations"
	@echo "  bootstrap            🔥 Complete setup: infrastructure + GitOps + ready to go!"
	@echo "  dev                  🚀 Start Tilt (infrastructure + apps with live reload)"
	@echo ""
	@echo "📂 Repository Management:"
	@echo "  check-repos          🔍 Check if all repositories are present"
	@echo "  update-repos         🔄 Pull latest changes for all repositories" 
	@echo "  repo-status          📊 Show git status for all repositories"
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
	@echo "  ✅ Check required repositories"
	@echo "  ✅ Install required tools (Tilt, Helm, kubectl)"
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
		echo "🔍 Step 0/6: Checking repositories..."; \
		$(MAKE) check-repos; \
		if [ ! -d "$(BACKEND_REPO_PATH)" ] || [ ! -d "$(DISCORD_REPO_PATH)" ]; then \
			echo ""; \
			echo "⚠️  Missing repositories detected!"; \
			echo "Choose how to get the repositories:"; \
			echo "  1. Auto-detect existing repos in common locations"; \
			echo "  2. Clone from remote repositories"; \
			echo "  3. Manually link to existing local repositories"; \
			echo "  4. Skip and continue (you'll set up repos later)"; \
			read -p "Enter your choice [1-4]: " -n 1 -r REPO_CHOICE; \
			echo ""; \
			case $$REPO_CHOICE in \
				1) \
					echo "🔍 Auto-detecting repositories..."; \
					$(MAKE) auto-detect-repos; \
					read -p "Press Enter to continue or Ctrl+C to abort..."; \
					;; \
				2) \
					echo "📂 Cloning repositories..."; \
					$(MAKE) clone-repos; \
					;; \
				3) \
					echo "🔗 Manual linking..."; \
					echo "Please run the link commands shown by auto-detect or use:"; \
					echo "  make link-repos BACKEND_PATH=/path/to/frolf-bot"; \
					echo "Then run bootstrap again."; \
					exit 1; \
					;; \
				4) \
					echo "⚠️  Continuing without repositories - you'll need to set them up later"; \
					;; \
				*) \
					echo "❌ Invalid choice. Please run 'make clone-repos' or 'make link-repos' manually"; \
					exit 1; \
					;; \
			esac; \
		fi; \
		echo ""; \
		echo "🔧 Step 1/6: Installing development tools..."; \
		$(MAKE) install-tools; \
		echo ""; \
		echo "📦 Step 2/6: Installing dependencies..."; \
		$(MAKE) install-deps; \
		echo ""; \
		echo "🏗️  Step 3/6: Setting up infrastructure (K8s + monitoring + storage)..."; \
		$(MAKE) setup-all; \
		echo ""; \
		echo "🎯 Step 4/6: Deploying ArgoCD ApplicationSets..."; \
		$(MAKE) deploy-applicationset; \
		echo ""; \
		echo "🏗️  Step 5/6: Adding Helm repositories..."; \
		$(MAKE) setup-helm-repos; \
		echo ""; \
		echo "🎉 BOOTSTRAP COMPLETE!"; \
		echo "=================="; \
		echo ""; \
		echo "🎯 What's Ready:"; \
		echo "  ✅ All repositories cloned and ready"; \
		echo "  ✅ Development tools installed"; \
		echo "  ✅ Infrastructure running"; \
		echo "  ✅ ArgoCD managing GitOps"; \
		echo "  ✅ Multi-tenant guild system active"; \
		echo "  ✅ Helm repositories configured"; \
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
		echo "  Grafana: http://localhost:3000 (admin/admin)"; \
		echo "  ArgoCD:  http://localhost:30080 (admin/<password>)"; \
		echo "  Backend: http://localhost:8080"; \
		echo "  NATS:    http://localhost:4222"; \
		echo "  PostgreSQL: http://localhost:5432"; \
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
		brew install tilt; \
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

setup-helm-repos: ## Add required Helm repositories
	@echo "📦 Setting up Helm repositories..."
	@helm repo add nats https://nats-io.github.io/k8s/helm/charts/ || echo "NATS repo already exists"
	@helm repo add bitnami https://charts.bitnami.com/bitnami || echo "Bitnami repo already exists"
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || echo "Prometheus repo already exists"
	@helm repo add grafana https://grafana.github.io/helm-charts || echo "Grafana repo already exists"
	@helm repo update
	@echo "✅ Helm repositories configured!"

setup-all: install-deps setup-helm-repos ## Setup complete local development environment
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
	@echo "This will start:"
	@echo "  🏗️  Infrastructure (NATS, PostgreSQL, Monitoring)"
	@echo "  🔧 Live reload for Go applications"
	@echo "  🌐 Port forwards for easy access"
	@echo ""
	@# Check repositories first
	@echo "🔍 Checking repositories..."
	@$(MAKE) check-repos
	@if [ ! -d "$(BACKEND_REPO_PATH)" ] || [ ! -d "$(DISCORD_REPO_PATH)" ]; then \
		echo "❌ Missing required repositories. Please run 'make clone-repos' or 'make link-repos' first."; \
		exit 1; \
	fi
	@# Check for Discord secret
	@if ! kubectl get secret discord-secrets -n frolf-bot >/dev/null 2>&1; then \
		echo "⚠️  Discord secret not found. Creating placeholder..."; \
		kubectl create namespace frolf-bot --dry-run=client -o yaml | kubectl apply -f -; \
		kubectl create secret generic discord-secrets --from-literal=token=YOUR_DISCORD_TOKEN_HERE -n frolf-bot; \
		echo "🔑 Don't forget to update with your real Discord token:"; \
		echo "   kubectl patch secret discord-secrets -n frolf-bot -p '{\"data\":{\"token\":\"<base64-encoded-token>\"}}'"; \
		echo ""; \
	fi
	@echo "🚀 Starting Tilt..."
	@echo "💡 You can customize the environment with:"
	@echo "   ENABLE_MONITORING=false make dev  # Skip monitoring stack"
	@echo ""
	tilt up

dev-down: ## Stop Tilt development environment
	@echo "🛑 Stopping Tilt development environment..."
	tilt down

dev-logs: ## Show Tilt logs
	@echo "📋 Showing Tilt logs..."
	tilt logs

build-images: ## Build Docker images locally (for testing)
	@echo "🏗️  Building application images..."
	@# Build from the parent directory to include shared modules
	@cd .. && docker build -f discord-frolf-bot/Dockerfile -t frolf-bot-discord:latest .
	@cd .. && docker build -f frolf-bot/Dockerfile -t frolf-bot-backend:latest .
	@echo "✅ Images built successfully!"

deploy-app: ## Deploy Frolf Bot application (without Tilt)
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
	@kubectl get namespaces | grep -E "(frolf-bot|nats|postgres|monitoring|observability|argocd)" || echo "No relevant namespaces found"
	@echo ""
	@echo "Pods in frolf-bot namespace:"
	@kubectl get pods -n frolf-bot 2>/dev/null || echo "No frolf-bot namespace found"
	@echo ""
	@echo "Infrastructure pods:"
	@echo "NATS:"
	@kubectl get pods -n nats 2>/dev/null || echo "No nats namespace found"
	@echo "PostgreSQL:"
	@kubectl get pods -n postgres 2>/dev/null || echo "No postgres namespace found"
	@echo "Monitoring:"
	@kubectl get pods -n monitoring 2>/dev/null || echo "No monitoring namespace found"
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
			echo "🛑 Stopping Tilt first..."; \
			tilt down --no-browser >/dev/null 2>&1 || true; \
		echo "🗑️  Removing all namespaces..."; \
		kubectl delete namespace frolf-bot monitoring observability argocd nats postgres --ignore-not-found=true; \
		echo "🗑️  Uninstalling Helm releases..."; \
		helm uninstall kube-prometheus-stack -n monitoring --ignore-not-found || true; \
		helm uninstall loki -n monitoring --ignore-not-found || true; \
		helm uninstall tempo -n monitoring --ignore-not-found || true; \
		helm uninstall alloy -n monitoring --ignore-not-found || true; \
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
	@echo "   - Stop Tilt"
	@echo "   - Stop Colima"
	@echo "   - Delete the entire VM"
	@echo "   - Start fresh with new cluster"
	@echo ""
	@read -p "Are you ABSOLUTELY sure? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "🛑 Stopping Tilt..."; \
		tilt down --no-browser >/dev/null 2>&1 || true; \
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
	@echo "Grafana:        http://localhost:3000 (admin/admin)"
	@echo "ArgoCD:         http://localhost:30080 (admin/<get-password>)"
	@echo "Backend API:    http://localhost:8080"
	@echo "NATS:          http://localhost:4222"  
	@echo "PostgreSQL:    http://localhost:5432"
	@echo ""
	@echo "🔑 Get ArgoCD password:"
	@echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"

tilt-status: ## Show Tilt status
	@echo "📊 Tilt Status:"
	@tilt get session 2>/dev/null || echo "Tilt not running"

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

# Repository configuration - UPDATE THESE URLs FOR YOUR PROJECT
BACKEND_REPO_URL ?= https://github.com/YOUR_ORG/frolf-bot.git
DISCORD_REPO_URL ?= https://github.com/YOUR_ORG/discord-frolf-bot.git
SHARED_REPO_URL ?= https://github.com/YOUR_ORG/frolf-bot-shared.git

# Local repository paths
BACKEND_REPO_PATH = ../frolf-bot
DISCORD_REPO_PATH = ../discord-frolf-bot
SHARED_REPO_PATH = ../frolf-bot-shared

# =====================================
# =====================================
# 🗄️  DATABASE MANAGEMENT
# =====================================

reset-db: ## ⚠️ Reset the local PostgreSQL database (deletes all data, keeps schema/migrations)
	@echo "\n💥 WARNING: This will ERASE ALL DATA in your local PostgreSQL database! (Deletes PVCs)"
	@read -p "Are you sure you want to reset the database? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "🛑 Stopping all apps that might use the DB..."; \
		tilt down --no-browser >/dev/null 2>&1 || true; \
		echo "🗑️  Deleting Postgres pod and PVCs..."; \
		kubectl delete pod -n postgres --selector=app.kubernetes.io/name=postgresql --ignore-not-found; \
		kubectl delete pvc -n postgres --all --ignore-not-found; \
		echo "🔄 Restarting Postgres deployment..."; \
		kubectl rollout restart deployment -n postgres || true; \
		echo "✅ Database reset!"; \
		echo "You may need to re-run migrations or restart your apps."; \
	else \
		echo "❌ Database reset cancelled"; \
	fi

truncate-db: ## ⚠️ Truncate all tables in the local PostgreSQL database (keeps schema/migrations)
	@echo "\n💥 WARNING: This will DELETE ALL ROWS in all tables in your local PostgreSQL database! (Keeps schema/migrations)"
	@read -p "Are you sure you want to TRUNCATE ALL TABLES? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "🔍 Locating Postgres pod..."; \
		PGPOD=$$(kubectl get pods -n postgres -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}'); \
		if [ -z "$$PGPOD" ]; then \
			echo "❌ No running Postgres pod found in 'postgres' namespace."; \
			exit 1; \
		fi; \
		echo "🔑 Getting database credentials from Kubernetes secrets..."; \
		POSTGRES_PASSWORD=$$(kubectl get secret -n postgres my-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d 2>/dev/null || echo "local"); \
		POSTGRES_DB=$$(kubectl get secret -n postgres my-postgresql -o jsonpath='{.data.database}' | base64 -d 2>/dev/null || echo "frolfbot"); \
		if [ -z "$$POSTGRES_DB" ]; then POSTGRES_DB="frolfbot"; fi; \
		echo "🗑️  Truncating all tables in database: $$POSTGRES_DB"; \
		echo "🔍 First, let's see what tables exist..."; \
		kubectl exec -n postgres $$PGPOD -- env PGPASSWORD="$$POSTGRES_PASSWORD" psql -U postgres -d "$$POSTGRES_DB" -c "SELECT schemaname, tablename FROM pg_tables WHERE schemaname IN ('public') ORDER BY schemaname, tablename;"; \
		echo "🗑️  Now truncating all tables..."; \
		kubectl exec -n postgres $$PGPOD -- env PGPASSWORD="$$POSTGRES_PASSWORD" psql -U postgres -d "$$POSTGRES_DB" -c "DO \$$\$$ DECLARE r RECORD; table_count INTEGER := 0; BEGIN FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP EXECUTE 'TRUNCATE TABLE ' || quote_ident(r.tablename) || ' RESTART IDENTITY CASCADE'; table_count := table_count + 1; RAISE NOTICE 'Truncated table: %', r.tablename; END LOOP; RAISE NOTICE 'Total tables truncated: %', table_count; END \$$\$$;"; \
		echo "✅ All tables truncated!"; \
	else \
		echo "❌ Truncate cancelled"; \
	fi
# 🗂️  REPOSITORY MANAGEMENT
# =====================================

clone-repos: ## Clone all required repositories to parent directory
	@echo "📂 Cloning all required repositories..."
	@echo "This will clone repos to the parent directory (alongside this infrastructure repo)"
	@echo ""
	@# Check if we're in the right place
	@if [ ! -f "Tiltfile" ]; then \
		echo "❌ This must be run from the infrastructure repository root"; \
		exit 1; \
	fi
	@# Clone backend repo
	@if [ ! -d "$(BACKEND_REPO_PATH)" ]; then \
		echo "📦 Cloning backend repository..."; \
		git clone $(BACKEND_REPO_URL) $(BACKEND_REPO_PATH); \
	else \
		echo "✅ Backend repository already exists at $(BACKEND_REPO_PATH)"; \
	fi
	@# Clone discord repo
	@if [ ! -d "$(DISCORD_REPO_PATH)" ]; then \
		echo "📦 Cloning Discord bot repository..."; \
		git clone $(DISCORD_REPO_URL) $(DISCORD_REPO_PATH); \
	else \
		echo "✅ Discord bot repository already exists at $(DISCORD_REPO_PATH)"; \
	fi
	@# Clone shared repo
	@if [ ! -d "$(SHARED_REPO_PATH)" ]; then \
		echo "📦 Cloning shared repository..."; \
		git clone $(SHARED_REPO_URL) $(SHARED_REPO_PATH); \
	else \
		echo "✅ Shared repository already exists at $(SHARED_REPO_PATH)"; \
	fi
	@echo ""
	@echo "✅ Repository cloning complete!"
	@echo "📂 Directory structure:"
	@echo "   📁 $(shell basename $(shell pwd))/ (infrastructure - this repo)"
	@echo "   📁 frolf-bot/ (backend API)"
	@echo "   📁 discord-frolf-bot/ (Discord bot)" 
	@echo "   📁 frolf-bot-shared/ (shared libraries)"
	@echo ""
	@echo "🚀 Next: Run 'make bootstrap' to set up the complete environment"

check-repos: ## Check if all required repositories are present
	@echo "🔍 Checking repository status..."
	@echo ""
	@# Check infrastructure repo (current directory)
	@echo "Infrastructure repo (current): ✅"
	@# Check other repos with detailed info
	@# Check backend repo
	@if [ -L "$(BACKEND_REPO_PATH)" ]; then \
		target=$$(readlink "$(BACKEND_REPO_PATH)"); \
		if [ -d "$(BACKEND_REPO_PATH)" ]; then \
			echo "Backend repo: ✅ 🔗 Symlinked to $$target"; \
		else \
			echo "Backend repo: ❌ 🔗 Broken symlink to $$target"; \
		fi; \
	elif [ -d "$(BACKEND_REPO_PATH)" ]; then \
		if [ -d "$(BACKEND_REPO_PATH)/.git" ]; then \
			echo "Backend repo: ✅ 📁 Git repository at $(BACKEND_REPO_PATH)"; \
		else \
			echo "Backend repo: ⚠️  📁 Directory exists but no .git found at $(BACKEND_REPO_PATH)"; \
		fi; \
	else \
		echo "Backend repo: ❌ Missing at $(BACKEND_REPO_PATH)"; \
	fi
	@# Check discord repo
	@if [ -L "$(DISCORD_REPO_PATH)" ]; then \
		target=$$(readlink "$(DISCORD_REPO_PATH)"); \
		if [ -d "$(DISCORD_REPO_PATH)" ]; then \
			echo "Discord repo: ✅ 🔗 Symlinked to $$target"; \
		else \
			echo "Discord repo: ❌ 🔗 Broken symlink to $$target"; \
		fi; \
	elif [ -d "$(DISCORD_REPO_PATH)" ]; then \
		if [ -d "$(DISCORD_REPO_PATH)/.git" ]; then \
			echo "Discord repo: ✅ 📁 Git repository at $(DISCORD_REPO_PATH)"; \
		else \
			echo "Discord repo: ⚠️  📁 Directory exists but no .git found at $(DISCORD_REPO_PATH)"; \
		fi; \
	else \
		echo "Discord repo: ❌ Missing at $(DISCORD_REPO_PATH)"; \
	fi
	@# Check shared repo (optional)
	@if [ -L "$(SHARED_REPO_PATH)" ]; then \
		target=$$(readlink "$(SHARED_REPO_PATH)"); \
		if [ -d "$(SHARED_REPO_PATH)" ]; then \
			echo "Shared repo (optional): ✅ 🔗 Symlinked to $$target"; \
		else \
			echo "Shared repo (optional): ❌ 🔗 Broken symlink to $$target"; \
		fi; \
	elif [ -d "$(SHARED_REPO_PATH)" ]; then \
		if [ -d "$(SHARED_REPO_PATH)/.git" ]; then \
			echo "Shared repo (optional): ✅ 📁 Git repository at $(SHARED_REPO_PATH)"; \
		else \
			echo "Shared repo (optional): ⚠️  📁 Directory exists but no .git found at $(SHARED_REPO_PATH)"; \
		fi; \
	else \
		echo "Shared repo (optional): ❌ Missing at $(SHARED_REPO_PATH)"; \
	fi
	@echo ""
	@# Count missing/broken repos (excluding optional shared repo)
	@missing_count=0; \
	broken_count=0; \
	for repo_path in "$(BACKEND_REPO_PATH)" "$(DISCORD_REPO_PATH)"; do \
		if [ -L "$$repo_path" ]; then \
			if [ ! -d "$$repo_path" ]; then \
				broken_count=$$((broken_count + 1)); \
			fi; \
		elif [ ! -d "$$repo_path" ]; then \
			missing_count=$$((missing_count + 1)); \
		fi; \
	done; \
	\
	if [ $$missing_count -eq 0 ] && [ $$broken_count -eq 0 ]; then \
		echo "🎉 All repositories are ready!"; \
		echo "💡 Run 'make dev' to start development environment"; \
	else \
		echo "⚠️  Repository issues found:"; \
		if [ $$missing_count -gt 0 ]; then \
			echo "   - $$missing_count missing repositories"; \
		fi; \
		if [ $$broken_count -gt 0 ]; then \
			echo "   - $$broken_count broken symlinks"; \
		fi; \
		echo ""; \
		echo "💡 Solutions:"; \
		echo "   1. Auto-detect existing repos: make auto-detect-repos"; \
		echo "   2. Link to existing repos: make link-repos BACKEND_PATH=/your/path"; \
		echo "   3. Clone missing repos: make clone-repos"; \
	fi

update-repos: ## Pull latest changes for all repositories
	@echo "🔄 Updating all repositories..."
	@echo ""
	@# Update infrastructure repo (current directory)
	@echo "📦 Updating infrastructure repo..."
	@git pull || echo "⚠️ Could not update infrastructure repo"
	@# Update other repos if they exist
	@if [ -d "$(BACKEND_REPO_PATH)" ]; then \
		echo "📦 Updating backend repo..."; \
		cd $(BACKEND_REPO_PATH) && git pull || echo "⚠️ Could not update backend repo"; \
	fi
	@if [ -d "$(DISCORD_REPO_PATH)" ]; then \
		echo "📦 Updating Discord repo..."; \
		cd $(DISCORD_REPO_PATH) && git pull || echo "⚠️ Could not update Discord repo"; \
	fi
	@if [ -d "$(SHARED_REPO_PATH)" ]; then \
		echo "📦 Updating shared repo..."; \
		cd $(SHARED_REPO_PATH) && git pull || echo "⚠️ Could not update shared repo"; \
	fi
	@echo ""
	@echo "✅ Repository updates complete!"

repo-status: ## Show git status for all repositories
	@echo "📊 Repository Status Overview:"
	@echo ""
	@echo "Infrastructure repo (current):"
	@git status --porcelain || echo "⚠️ Not a git repository"
	@echo ""
	@if [ -d "$(BACKEND_REPO_PATH)" ]; then \
		echo "Backend repo:"; \
		cd $(BACKEND_REPO_PATH) && git status --porcelain || echo "⚠️ Not a git repository"; \
		echo ""; \
	fi
	@if [ -d "$(DISCORD_REPO_PATH)" ]; then \
		echo "Discord repo:"; \
		cd $(DISCORD_REPO_PATH) && git status --porcelain || echo "⚠️ Not a git repository"; \
		echo ""; \
	fi
	@if [ -d "$(SHARED_REPO_PATH)" ]; then \
		echo "Shared repo:"; \
		cd $(SHARED_REPO_PATH) && git status --porcelain || echo "⚠️ Not a git repository"; \
		echo ""; \
	fi

verify-setup: ## 🔍 Verify development environment setup
	@echo "🔍 Running comprehensive setup verification..."
	@./scripts/verify-setup.sh

onboard: ## 🎮 Interactive onboarding for new developers
	@echo "🎮 Starting interactive onboarding for new developers..."
	@./scripts/onboard.sh

# =====================================
# 🔗  REPOSITORY LINKING
# =====================================

link-repos: ## 🔗 Link to existing local repositories (usage: make link-repos BACKEND_PATH=/path/to/backend)
	@echo "🔗 Linking to existing local repositories..."
	@echo "This creates symlinks to your existing repositories instead of cloning."
	@echo ""
	@# Function to create symlink with confirmation
	@create_link() { \
		local target_path="$$1"; \
		local link_name="$$2"; \
		local repo_name="$$3"; \
		if [ -z "$$target_path" ]; then \
			echo "❌ No path provided for $$repo_name"; \
			echo "   Usage: make link-repos $$repo_name""_PATH=/path/to/repo"; \
			return 1; \
		fi; \
		if [ ! -d "$$target_path" ]; then \
			echo "❌ Directory $$target_path does not exist"; \
			return 1; \
		fi; \
		if [ -e "$$link_name" ]; then \
			if [ -L "$$link_name" ]; then \
				echo "🔗 Symlink $$link_name already exists, removing..."; \
				rm "$$link_name"; \
			else \
				echo "❌ $$link_name already exists and is not a symlink"; \
				echo "   Please remove it manually first"; \
				return 1; \
			fi; \
		fi; \
		echo "🔗 Creating symlink: $$link_name -> $$target_path"; \
		ln -s "$$target_path" "$$link_name"; \
		echo "✅ Linked $$repo_name successfully"; \
	}; \
	\
	linked_any=false; \
	if [ -n "$(BACKEND_PATH)" ]; then \
		create_link "$(BACKEND_PATH)" "$(BACKEND_REPO_PATH)" "backend" && linked_any=true; \
	fi; \
	if [ -n "$(DISCORD_PATH)" ]; then \
		create_link "$(DISCORD_PATH)" "$(DISCORD_REPO_PATH)" "discord" && linked_any=true; \
	fi; \
	if [ -n "$(SHARED_PATH)" ]; then \
		create_link "$(SHARED_PATH)" "$(SHARED_REPO_PATH)" "shared" && linked_any=true; \
	fi; \
	\
	if [ "$$linked_any" = false ]; then \
		echo "💡 No repository paths provided. Usage examples:"; \
		echo "   make link-repos BACKEND_PATH=/path/to/frolf-bot"; \
		echo "   make link-repos DISCORD_PATH=/path/to/discord-frolf-bot"; \
		echo "   make link-repos SHARED_PATH=/path/to/frolf-bot-shared"; \
		echo "   make link-repos BACKEND_PATH=/path/to/frolf-bot DISCORD_PATH=/path/to/discord-frolf-bot"; \
		echo ""; \
		echo "Or set all at once:"; \
		echo "   make link-repos \\"; \
		echo "     BACKEND_PATH=/path/to/frolf-bot \\"; \
		echo "     DISCORD_PATH=/path/to/discord-frolf-bot \\"; \
		echo "     SHARED_PATH=/path/to/frolf-bot-shared"; \
	else \
		echo ""; \
		echo "✅ Repository linking complete!"; \
		echo "📂 Directory structure:"; \
		echo "   📁 $(shell basename $(shell pwd))/ (infrastructure - this repo)"; \
		if [ -L "$(BACKEND_REPO_PATH)" ]; then echo "   🔗 frolf-bot/ -> $$(readlink $(BACKEND_REPO_PATH))"; fi; \
		if [ -L "$(DISCORD_REPO_PATH)" ]; then echo "   🔗 discord-frolf-bot/ -> $$(readlink $(DISCORD_REPO_PATH))"; fi; \
		if [ -L "$(SHARED_REPO_PATH)" ]; then echo "   🔗 frolf-bot-shared/ -> $$(readlink $(SHARED_REPO_PATH))"; fi; \
		echo ""; \
		echo "🚀 Next: Run 'make bootstrap' to set up the infrastructure"; \
	fi

auto-detect-repos: ## 🔍 Auto-detect repositories in common locations
	@echo "🔍 Auto-detecting repositories in common locations..."
	@echo ""
	@# Common patterns where repos might be found
	@search_paths=( \
		"../" \
		"../../" \
		"$$HOME/Documents/GitHub/" \
		"$$HOME/Projects/" \
		"$$HOME/Code/" \
		"$$HOME/Development/" \
		"$$HOME/go/src/" \
	); \
	\
	found_backend=""; \
	found_discord=""; \
	found_shared=""; \
	\
	for base_path in "$${search_paths[@]}"; do \
		if [ -d "$$base_path" ]; then \
			echo "🔍 Searching in $$base_path..."; \
			if [ -z "$$found_backend" ] && [ -d "$$base_path/frolf-bot" ] && [ -d "$$base_path/frolf-bot/.git" ]; then \
				echo "  ✅ Found frolf-bot at $$base_path/frolf-bot"; \
				found_backend="$$base_path/frolf-bot"; \
			fi; \
			if [ -z "$$found_discord" ] && [ -d "$$base_path/discord-frolf-bot" ] && [ -d "$$base_path/discord-frolf-bot/.git" ]; then \
				echo "  ✅ Found discord-frolf-bot at $$base_path/discord-frolf-bot"; \
				found_discord="$$base_path/discord-frolf-bot"; \
			fi; \
			if [ -z "$$found_shared" ] && [ -d "$$base_path/frolf-bot-shared" ] && [ -d "$$base_path/frolf-bot-shared/.git" ]; then \
				echo "  ✅ Found frolf-bot-shared at $$base_path/frolf-bot-shared"; \
				found_shared="$$base_path/frolf-bot-shared"; \
			fi; \
		fi; \
	done; \
	\
	if [ -n "$$found_backend" ] || [ -n "$$found_discord" ] || [ -n "$$found_shared" ]; then \
		echo ""; \
		echo "📋 Found repositories (first occurrence only):"; \
		if [ -n "$$found_backend" ]; then \
			echo "  frolf-bot -> $$found_backend"; \
		fi; \
		if [ -n "$$found_discord" ]; then \
			echo "  discord-frolf-bot -> $$found_discord"; \
		fi; \
		if [ -n "$$found_shared" ]; then \
			echo "  frolf-bot-shared -> $$found_shared"; \
		fi; \
		echo ""; \
		echo "💡 To link these repositories, run:"; \
		if [ -n "$$found_backend" ]; then \
			echo "   make link-repos BACKEND_PATH=$$found_backend"; \
		fi; \
		if [ -n "$$found_discord" ]; then \
			echo "   make link-repos DISCORD_PATH=$$found_discord"; \
		fi; \
		if [ -n "$$found_shared" ]; then \
			echo "   make link-repos SHARED_PATH=$$found_shared  # (optional)"; \
		fi; \
		echo ""; \
		echo "💡 Or link all at once:"; \
		link_cmd="make link-repos"; \
		if [ -n "$$found_backend" ]; then \
			link_cmd="$$link_cmd BACKEND_PATH=$$found_backend"; \
		fi; \
		if [ -n "$$found_discord" ]; then \
			link_cmd="$$link_cmd DISCORD_PATH=$$found_discord"; \
		fi; \
		if [ -n "$$found_shared" ]; then \
			link_cmd="$$link_cmd SHARED_PATH=$$found_shared"; \
		fi; \
		echo "   $$link_cmd"; \
	else \
		echo "❌ No repositories found in common locations."; \
		echo "💡 You can either:"; \
		echo "   1. Clone repositories: make clone-repos"; \
		echo "   2. Manually link: make link-repos BACKEND_PATH=/your/path"; \
	fi

# =====================================
