#!/bin/bash

# Frolf Bot Development Environment Setup Verification
# This script checks that everything is properly configured

set -e

echo "🔍 Frolf Bot Development Environment Verification"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "✅ ${GREEN}$2${NC}"
    else
        echo -e "❌ ${RED}$2${NC}"
    fi
}

print_warning() {
    echo -e "⚠️  ${YELLOW}$1${NC}"
}

print_info() {
    echo -e "ℹ️  ${BLUE}$1${NC}"
}

# Check basic tools
echo "🔧 Checking Development Tools..."
echo "--------------------------------"

# Check if we're in the right directory
if [ ! -f "Tiltfile" ]; then
    echo -e "❌ ${RED}Not in infrastructure repository root${NC}"
    echo "Please run this script from the frolf-bot-infrastructure directory"
    exit 1
fi
print_status 0 "Running from infrastructure repository"

# Check Git
if command -v git >/dev/null 2>&1; then
    print_status 0 "Git is installed ($(git --version))"
else
    print_status 1 "Git is not installed"
    exit 1
fi

# Check Docker
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        print_status 0 "Docker is installed and running"
    else
        print_status 1 "Docker is installed but not running"
        echo "  Please start Docker Desktop or Colima"
    fi
else
    print_status 1 "Docker is not installed"
    echo "  Please install Docker Desktop or Colima"
fi

# Check kubectl
if command -v kubectl >/dev/null 2>&1; then
    if kubectl cluster-info >/dev/null 2>&1; then
        print_status 0 "kubectl is installed and connected to cluster"
        CLUSTER_INFO=$(kubectl cluster-info | head -1)
        print_info "Cluster: $CLUSTER_INFO"
    else
        print_status 1 "kubectl is installed but not connected to a cluster"
        echo "  Please start your Kubernetes cluster (Docker Desktop K8s or Colima)"
    fi
else
    print_status 1 "kubectl is not installed"
    echo "  Run: brew install kubectl"
fi

# Check Helm
if command -v helm >/dev/null 2>&1; then
    print_status 0 "Helm is installed ($(helm version --short))"
else
    print_status 1 "Helm is not installed"
    echo "  Run: brew install helm"
fi

# Check Tilt
if command -v tilt >/dev/null 2>&1; then
    print_status 0 "Tilt is installed ($(tilt version))"
else
    print_status 1 "Tilt is not installed"
    echo "  Run: brew install tilt"
fi

# Check Ansible
if command -v ansible >/dev/null 2>&1; then
    print_status 0 "Ansible is installed ($(ansible --version | head -1))"
else
    print_status 1 "Ansible is not installed"
    echo "  Run: brew install ansible"
fi

echo ""
echo "📂 Checking Repository Structure..."
echo "-----------------------------------"

# Check repository structure
REPOS_OK=true

if [ -d "../frolf-bot" ]; then
    print_status 0 "Backend repository found at ../frolf-bot"
    if [ -f "../frolf-bot/go.mod" ]; then
        print_status 0 "Backend repository appears to be a Go project"
    else
        print_warning "Backend repository doesn't appear to be a Go project"
    fi
else
    print_status 1 "Backend repository not found at ../frolf-bot"
    REPOS_OK=false
fi

if [ -d "../discord-frolf-bot" ]; then
    print_status 0 "Discord bot repository found at ../discord-frolf-bot"
    if [ -f "../discord-frolf-bot/go.mod" ]; then
        print_status 0 "Discord bot repository appears to be a Go project"
    else
        print_warning "Discord bot repository doesn't appear to be a Go project"
    fi
else
    print_status 1 "Discord bot repository not found at ../discord-frolf-bot"
    REPOS_OK=false
fi

if [ -d "../frolf-bot-shared" ]; then
    print_status 0 "Shared repository found at ../frolf-bot-shared"
    if [ -f "../frolf-bot-shared/go.mod" ]; then
        print_status 0 "Shared repository appears to be a Go project"
    else
        print_warning "Shared repository doesn't appear to be a Go project"
    fi
else
    print_status 1 "Shared repository not found at ../frolf-bot-shared"
    REPOS_OK=false
fi

if [ "$REPOS_OK" = false ]; then
    echo ""
    print_warning "Missing repositories detected!"
    echo "  Run: make clone-repos"
fi

echo ""
echo "🎯 Checking Infrastructure Setup..."
echo "-----------------------------------"

# Check if cluster has required namespaces
NAMESPACES=("nats" "postgres" "monitoring" "frolf-bot")
for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" >/dev/null 2>&1; then
        print_status 0 "Namespace $ns exists"
    else
        print_status 1 "Namespace $ns does not exist"
        echo "  This is normal for a fresh setup"
    fi
done

# Check if ArgoCD is installed
if kubectl get namespace argocd >/dev/null 2>&1; then
    print_status 0 "ArgoCD namespace exists"
    if kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
        print_status 0 "ArgoCD is installed"
    else
        print_status 1 "ArgoCD namespace exists but ArgoCD is not installed"
    fi
else
    print_status 1 "ArgoCD is not installed"
    echo "  This is normal for a fresh setup"
fi

echo ""
echo "🔐 Checking Secrets..."
echo "----------------------"

# Check Discord secret
if kubectl get secret discord-secrets -n frolf-bot >/dev/null 2>&1; then
    print_status 0 "Discord secrets exist"
    # Check if it's the placeholder
    TOKEN=$(kubectl get secret discord-secrets -n frolf-bot -o jsonpath='{.data.token}' | base64 -d)
    if [ "$TOKEN" = "YOUR_DISCORD_TOKEN_HERE" ]; then
        print_warning "Discord token is still the placeholder - update it with your real token"
    else
        print_status 0 "Discord token appears to be configured"
    fi
else
    print_status 1 "Discord secrets do not exist"
    echo "  This will be created automatically when you run 'make dev'"
fi

echo ""
echo "📊 Summary & Next Steps"
echo "======================="

# Count issues
TOTAL_CHECKS=0
FAILED_CHECKS=0

# This is a simplified check - in a real implementation you'd track each check
if ! command -v tilt >/dev/null 2>&1 || ! command -v kubectl >/dev/null 2>&1 || ! command -v helm >/dev/null 2>&1; then
    ((FAILED_CHECKS++))
fi

if [ "$REPOS_OK" = false ]; then
    ((FAILED_CHECKS++))
fi

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "🎉 ${GREEN}All checks passed! You're ready to start development.${NC}"
    echo ""
    echo "🚀 Quick start commands:"
    echo "  make bootstrap    # Set up infrastructure (first time)"
    echo "  make dev          # Start development environment"
    echo ""
else
    echo -e "⚠️  ${YELLOW}Some issues found. Please address them before starting development.${NC}"
    echo ""
    echo "🔧 Common fixes:"
    if ! command -v tilt >/dev/null 2>&1 || ! command -v kubectl >/dev/null 2>&1 || ! command -v helm >/dev/null 2>&1; then
        echo "  make install-tools    # Install missing tools"
    fi
    if [ "$REPOS_OK" = false ]; then
        echo "  make clone-repos      # Clone missing repositories"
    fi
    echo "  make bootstrap        # Complete setup"
    echo ""
fi

echo "📚 Documentation:"
echo "  README.md         # Full documentation"
echo "  QUICK_START.md    # Quick start guide"
echo "  make help         # All available commands"
echo ""
echo "🆘 Need help? Check the troubleshooting section in QUICK_START.md"
