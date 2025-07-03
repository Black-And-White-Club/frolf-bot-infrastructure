#!/bin/bash
# Create a new Discord guild environment

set -e

GUILD_ID="$1"
TIER="${2:-free}"
DISCORD_TOKEN="$3"

if [ -z "$GUILD_ID" ]; then
    echo "Usage: $0 <guild-id> [tier] [discord-token]"
    echo "  guild-id: Discord guild/server ID"
    echo "  tier: free|pro|enterprise (default: free)"
    echo "  discord-token: Discord bot token for this guild"
    exit 1
fi

NAMESPACE="guild-$GUILD_ID"

echo "🚀 Creating guild environment for Guild ID: $GUILD_ID"
echo "📊 Tier: $TIER"
echo "🏷️  Namespace: $NAMESPACE"

# Create namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Label namespace with tier and guild info
kubectl label namespace "$NAMESPACE" \
    app.kubernetes.io/name=frolf-bot \
    app.kubernetes.io/component=guild \
    frolf-bot.io/guild-id="$GUILD_ID" \
    frolf-bot.io/tier="$TIER" \
    --overwrite

# Create Discord token secret if provided
if [ -n "$DISCORD_TOKEN" ]; then
    kubectl create secret generic discord-secrets \
        --from-literal=token="$DISCORD_TOKEN" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ Discord token secret created"
fi

# Apply tier-specific resources
case $TIER in
    "free")
        echo "📦 Deploying free tier resources..."
        envsubst < multi-tenant/templates/guild-template-free.yaml | kubectl apply -f -
        ;;
    "pro") 
        echo "📦 Deploying pro tier resources..."
        envsubst < multi-tenant/templates/guild-template-pro.yaml | kubectl apply -f -
        ;;
    "enterprise")
        echo "📦 Deploying enterprise tier resources..."
        envsubst < multi-tenant/templates/guild-template-enterprise.yaml | kubectl apply -f -
        ;;
    *)
        echo "❌ Unknown tier: $TIER"
        exit 1
        ;;
esac

# Set resource quotas based on tier
case $TIER in
    "free")
        kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: guild-quota
  namespace: $NAMESPACE
spec:
  hard:
    requests.memory: "256Mi"
    requests.cpu: "200m"
    limits.memory: "512Mi"
    limits.cpu: "400m"
    pods: "3"
EOF
        ;;
    "pro")
        kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: guild-quota
  namespace: $NAMESPACE
spec:
  hard:
    requests.memory: "1Gi"
    requests.cpu: "1000m"
    limits.memory: "2Gi"
    limits.cpu: "2000m"
    pods: "10"
EOF
        ;;
    "enterprise")
        # No resource quotas for enterprise tier
        echo "🎯 Enterprise tier - no resource quotas"
        ;;
esac

echo "✅ Guild $GUILD_ID ($TIER tier) created successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Update DNS/ingress for guild-specific endpoints"
echo "  2. Configure guild-specific monitoring dashboards"
echo "  3. Test guild deployment: kubectl get pods -n $NAMESPACE"
