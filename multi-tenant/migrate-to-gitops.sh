#!/bin/bash
# Migration script from bash-based guild management to GitOps approach
# This script helps migrate existing guilds to the new ArgoCD ApplicationSet approach

set -e

echo "🔄 Migrating to GitOps Guild Management"
echo "======================================"
echo ""

# Check if we're in the right directory
if [[ ! -f "multi-tenant/create-guild.sh" ]]; then
    echo "❌ Please run this script from the repository root"
    exit 1
fi

# Check for existing guild namespaces
echo "🔍 Scanning for existing guild namespaces..."
EXISTING_GUILDS=$(kubectl get namespaces -l app.kubernetes.io/component=guild -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

if [[ -z "$EXISTING_GUILDS" ]]; then
    echo "✅ No existing guild namespaces found. You can start fresh with the GitOps approach."
    echo ""
    echo "Next steps:"
    echo "1. Deploy the ApplicationSet: make deploy-applicationset"
    echo "2. Create your first guild: make create-guild GUILD_ID=123456789 TIER=free"
    exit 0
fi

echo "📋 Found existing guild namespaces: $EXISTING_GUILDS"
echo ""

# Create the guild configurations directory if it doesn't exist
mkdir -p multi-tenant/guilds

# Process each existing guild
for namespace in $EXISTING_GUILDS; do
    # Extract guild ID from namespace name
    GUILD_ID=${namespace#guild-}
    
    echo "🔧 Processing guild: $GUILD_ID"
    
    # Try to determine tier from resource limits
    DISCORD_MEMORY_LIMIT=$(kubectl get deployment discord-bot -n "$namespace" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo "128Mi")
    
    if [[ "$DISCORD_MEMORY_LIMIT" == "128Mi" ]]; then
        TIER="free"
    else
        TIER="pro"
    fi
    
    echo "  - Detected tier: $TIER"
    
    # Create guild configuration file
    cat > "multi-tenant/guilds/guild-${GUILD_ID}.yaml" << EOF
guild_id: "${GUILD_ID}"
tier: "${TIER}"
discord_memory_request: "64Mi"
discord_memory_limit: "${DISCORD_MEMORY_LIMIT}"
discord_cpu_request: "50m"
discord_cpu_limit: "100m"
backend_memory_request: "128Mi"
backend_memory_limit: "256Mi"
backend_cpu_request: "100m"
backend_cpu_limit: "200m"
EOF
    
    echo "  ✅ Created configuration: multi-tenant/guilds/guild-${GUILD_ID}.yaml"
done

echo ""
echo "✅ Migration preparation complete!"
echo ""
echo "Next steps:"
echo "1. Review the generated configuration files in multi-tenant/guilds/"
echo "2. Commit the configuration files to git:"
echo "   git add multi-tenant/guilds/"
echo "   git commit -m 'Migrate existing guilds to GitOps configuration'"
echo "   git push"
echo "3. Deploy the ApplicationSet: make deploy-applicationset"
echo "4. ArgoCD will reconcile existing resources with the new configuration"
echo "5. Test the new guild management commands:"
echo "   make list-guilds"
echo "   make guild-status GUILD_ID=<your-guild-id>"
echo ""
echo "⚠️  Note: Keep your existing guilds running during this migration."
echo "   ArgoCD will adopt and manage them without disruption."
echo ""
echo "🗑️  Once you've verified everything works, you can remove:"
echo "   - multi-tenant/create-guild.sh"
echo "   - multi-tenant/templates/ (legacy templates)"
