# Tiltfile for Frolf Bot Local Development
# Run with: tilt up

# Load Tilt extensions
load('ext://helm_resource', 'helm_resource', 'helm_repo')

# Increase timeouts for slower operations
update_settings(k8s_upsert_timeout_secs=300)

# Your repo paths
BACKEND_PATH = '/Users/jace/Documents/GitHub/frolf-bot'
DISCORD_PATH = '/Users/jace/Documents/GitHub/discord-frolf-bot'

# Add Helm repos
helm_repo('bitnami', 'https://charts.bitnami.com/bitnami')
helm_repo('nats', 'https://nats-io.github.io/k8s/helm/charts')
helm_repo('prometheus-community', 'https://prometheus-community.github.io/helm-charts')
helm_repo('grafana', 'https://grafana.github.io/helm-charts')

# Create namespaces to match your existing structure
k8s_yaml(blob("""
apiVersion: v1
kind: Namespace
metadata:
  name: frolf-bot
---
apiVersion: v1
kind: Namespace
metadata:
  name: nats
---
apiVersion: v1
kind: Namespace
metadata:
  name: postgres
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
"""))

# Install infrastructure with Helm
helm_resource(
    'postgres-helm',
    'bitnami/postgresql',
    namespace='postgres',
    flags=['--values=local-dev/values/postgres-local.yaml'],
    labels=['infrastructure']
)

helm_resource(
    'nats-helm', 
    'nats/nats',
    namespace='nats',
    flags=['--values=local-dev/values/nats-local.yaml'],
    labels=['infrastructure']
)

# Monitoring stack for local development
helm_resource(
    'monitoring-stack',
    'prometheus-community/kube-prometheus-stack',
    namespace='monitoring',
    flags=[
        '--set=grafana.persistence.enabled=false',
        '--set=grafana.adminPassword=admin',
        '--set=grafana.service.type=NodePort',
        '--set=grafana.service.nodePort=30000',
        '--set=alertmanager.enabled=false',
        '--set=grafana.sidecar.datasources.defaultDatasourceEnabled=true',
        '--timeout=10m'
    ],
    labels=['monitoring'],
    port_forwards=['3000:3000']
)

# Build and deploy your applications with live reload
docker_build(
    'frolf-bot-backend:latest',
    BACKEND_PATH,
    live_update=[
        sync(BACKEND_PATH, '/app'),
        run('go mod download', trigger=['go.mod', 'go.sum']),  # Go project, not npm
    ]
)

docker_build(
    'frolf-bot-discord:latest', 
    DISCORD_PATH,
    live_update=[
        sync(DISCORD_PATH, '/app'),
        run('go mod download', trigger=['go.mod', 'go.sum']),  # Go project, not npm
    ]
)

# Apply your application manifests (individual files)
k8s_yaml([
    'frolf-bot-app-manifests/backend-deployment.yaml',
    'frolf-bot-app-manifests/discord-deployment.yaml', 
    'frolf-bot-app-manifests/ingress.yaml',
    'frolf-bot-app-manifests/my-nats-service.yaml',
    'frolf-bot-app-manifests/my-postgresql-service.yaml'
])

# Configure your applications
k8s_resource('frolf-bot-backend', port_forwards='8080:8080', labels=['applications'])
k8s_resource('frolf-bot-discord', labels=['applications'])

# Configure infrastructure resources (use the actual Helm release names)
k8s_resource('postgres-helm', labels=['infrastructure'])
k8s_resource('nats-helm', labels=['infrastructure'])
k8s_resource('monitoring-stack', labels=['monitoring'])

# Create Discord secret if it doesn't exist
local_resource(
    'discord-secret',
    'kubectl get secret discord-secrets -n frolf-bot || echo "⚠️  Please create Discord secret: kubectl create secret generic discord-secrets --from-literal=token=YOUR_TOKEN -n frolf-bot"',
    deps=[],
    labels=['setup']
)

print("""
🚀 Frolf Bot Development Environment with Tilt

Infrastructure:
- PostgreSQL: Available in cluster
- NATS: Available in cluster  
- Prometheus/Grafana: http://localhost:3000 (admin/admin)
- Grafana (NodePort): http://localhost:30000 (admin/admin)

Applications:
- Backend: http://localhost:8080 (with live reload)
- Discord Bot: Running in cluster (with live reload)

Setup:
1. Create Discord secret if not done:
   kubectl create secret generic discord-secrets --from-literal=token=YOUR_TOKEN -n frolf-bot

2. Make changes to your code - Tilt will automatically rebuild and deploy!

Press 'space' to open Tilt UI, 'q' to quit
""")
