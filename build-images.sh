#!/bin/bash
# Script to build and load your application images into the local cluster

set -e

echo "🏗️  Building and loading Frolf Bot application images..."

# Configuration - Your actual repo paths
BACKEND_REPO_PATH="${BACKEND_REPO_PATH:-/Users/jace/Documents/GitHub/frolf-bot}"
DISCORD_REPO_PATH="${DISCORD_REPO_PATH:-/Users/jace/Documents/GitHub/discord-frolf-bot}"

# Function to build and load image
build_and_load() {
    local app_name=$1
    local repo_path=$2
    local image_name="frolf-bot-${app_name}:latest"
    
    echo "Building ${app_name} from ${repo_path}..."
    
    if [ -d "$repo_path" ]; then
        # Build the image from the repo directory
        docker build -t "$image_name" "$repo_path"
        
        # Load into cluster (works for kind, k3d, and Colima)
        if command -v colima &> /dev/null && colima status &> /dev/null; then
            echo "✅ Image $image_name built and available in Colima"
        elif command -v kind &> /dev/null; then
            echo "Loading $image_name into kind cluster..."
            kind load docker-image "$image_name"
        elif command -v k3d &> /dev/null; then
            echo "Loading $image_name into k3d cluster..."
            k3d image import "$image_name"
        else
            echo "✅ Image $image_name built and available in Docker daemon"
        fi
    else
        echo "❌ Repository not found at $repo_path"
        echo "Please update the path in this script or set environment variables:"
        echo "  BACKEND_REPO_PATH=/path/to/backend"
        echo "  DISCORD_REPO_PATH=/path/to/discord-bot"
        echo ""
        echo "Or build manually with:"
        echo "  docker build -t frolf-bot-${app_name}:latest /path/to/your/${app_name}-repo"
        return 1
    fi
}

# Build your applications
echo "Building backend from: $BACKEND_REPO_PATH"
build_and_load "backend" "$BACKEND_REPO_PATH"

echo "Building Discord bot from: $DISCORD_REPO_PATH"  
build_and_load "discord" "$DISCORD_REPO_PATH"

echo ""
echo "✅ Application images ready!"
echo ""
echo "Next steps:"
echo "1. Add your Discord token: kubectl create secret generic discord-secrets --from-literal=token=YOUR_TOKEN -n frolf-bot"
echo "2. Deploy: kubectl apply -f frolf-bot-app-manifests/"
echo "3. Check status: kubectl get pods -n frolf-bot"
