# Tiltfile for Frolf Bot Infrastructure (multi-repo dev)

# Load extensions

# Load extensions
load('ext://helm_remote', 'helm_remote')
load('ext://git_resource', 'git_checkout')
load('ext://ko', 'ko_build')

# --- Configuration Management ---
config.define_string_list("repos", args=False, usage="Repository URLs to clone")
config.define_string("git_branch", args=False, usage="Git branch to checkout")
config.define_bool("enable_monitoring", args=False, usage="Enable monitoring stack")
config.define_bool("enable_tracing", args=False, usage="Enable distributed tracing")
config.define_bool("enable_profiling", args=False, usage="Enable profiling tools")

cfg = config.parse()

# Environment-based configuration with sensible defaults
ENABLE_MONITORING = cfg.get("enable_monitoring", os.getenv('ENABLE_MONITORING', 'true').lower() == 'true')
ENABLE_TRACING = cfg.get("enable_tracing", os.getenv('ENABLE_TRACING', 'false').lower() == 'true')
ENABLE_PROFILING = cfg.get("enable_profiling", os.getenv('ENABLE_PROFILING', 'false').lower() == 'true')

# Repository configuration
DEFAULT_REPOS = {
    'frolf-bot': 'https://github.com/YOUR_ORG/frolf-bot.git',
    'discord-frolf-bot': 'https://github.com/YOUR_ORG/discord-frolf-bot.git'
}

# Repository paths with better defaults
FROLF_BOT_REPO = os.getenv('FROLF_BOT_REPO', '../frolf-bot')
DISCORD_BOT_REPO = os.getenv('DISCORD_BOT_REPO', '../discord-frolf-bot')

# Development mode detection
IS_CI = os.getenv('CI', 'false').lower() == 'true'
IS_TEARDOWN = os.getenv('TILT_MODE', '') == 'down'

# --- Local Secret Helper ---
def ensure_backend_secret():
    # Only run in local dev, not CI or teardown
    if IS_CI or IS_TEARDOWN:
        return

    # Check for kubectl
    result = local('which kubectl', quiet=True)
    if hasattr(result, 'exit_code') and result.exit_code != 0:
        print('❌ kubectl not found! Please install kubectl and ensure it is in your PATH.')
        fail('kubectl is required for local secret automation.')

    # Require manifest for secrets; no inline fallback
    if not os.path.exists('frolf-bot-app-manifests/backend-secrets.yaml'):
        print('❌ backend-secrets.yaml not found! Please create frolf-bot-app-manifests/backend-secrets.yaml with your local dev secrets.')
        fail('backend-secrets.yaml is required for local development.')

    result = local('kubectl get secret backend-secrets -n frolf-bot || true', quiet=True)
    if hasattr(result, 'exit_code') and result.exit_code == 0:
        return
    print('🔑 Applying backend-secrets.yaml for local dev...')
    local('kubectl create namespace frolf-bot --dry-run=client -o yaml | kubectl apply -f -', quiet=True)
    local('kubectl apply -f frolf-bot-app-manifests/backend-secrets.yaml', quiet=True)
    print('✅ backend-secrets created from manifest.')

ensure_backend_secret()

# --- Helper Functions ---
def ensure_repo_exists(repo_path, repo_name, repo_url, optional=False):
    """Check if repository exists and provide helpful guidance if not."""
    if IS_TEARDOWN:
        return True
        
    if not os.path.exists(repo_path):
        if optional:
            print("⚠️  Optional repository %s not found at %s (skipping)" % (repo_name, repo_path))
            return False
        else:
            print("❌ Repository %s not found at %s" % (repo_name, repo_path))
            print("💡 Quick fix: make clone-repos")
            print("   Or manually: git clone %s %s" % (repo_url, repo_path))
            fail('Repository %s not found' % repo_name)
    
    print("✅ Found repository: %s" % repo_path)
    return True


# --- KO Build Config ---
# Use ko_build for Go apps, leveraging .ko.yaml in each repo
print("DOCKER_HOST in Tiltfile:", os.getenv('DOCKER_HOST'))

# --- Repository Discovery ---
if not IS_TEARDOWN:
    print("🔍 Repository Discovery:")
    print("=" * 50)
    
    repo_status = {
        'backend': ensure_repo_exists(FROLF_BOT_REPO, 'frolf-bot', DEFAULT_REPOS['frolf-bot']),
        'discord': ensure_repo_exists(DISCORD_BOT_REPO, 'discord-frolf-bot', DEFAULT_REPOS['discord-frolf-bot'])
    }
    
    print("=" * 50)
else:
    repo_status = {'backend': True, 'discord': True}

# --- KO Builds ---
os.environ['KO_DOCKER_REPO'] = 'ko.local'
os.environ['KO_FLAGS'] = '--local'
if repo_status['backend']:
    ko_build('frolf-bot-backend', './', dir=FROLF_BOT_REPO)

if repo_status['discord']:
    ko_build('frolf-bot-discord', './', dir=DISCORD_BOT_REPO)

# --- Infrastructure Stack ---
def deploy_core_infrastructure():
    """Deploy core infrastructure components."""
    # NATS
    helm_remote('nats',
        repo_name='nats-charts',
        repo_url='https://nats-io.github.io/k8s/helm/charts/',
        release_name='my-nats',
        namespace='nats',
        values=['charts/nats/values.yaml', 'local-dev/values/nats-local.yaml'],
        create_namespace=True
    )
    
    # PostgreSQL
    helm_remote('postgresql',
        repo_name='bitnami-charts',
        repo_url='https://charts.bitnami.com/bitnami',
        release_name='my-postgresql',
        namespace='postgres',
        values=['charts/postgres/values.yaml', 'local-dev/values/postgres-local.yaml'],
        create_namespace=True
    )

def deploy_monitoring_stack():
    """Deploy monitoring and observability stack."""
    if not ENABLE_MONITORING:
        return
        
    # Prometheus + Grafana
    helm_remote('kube-prometheus-stack',
        repo_name='prometheus-community',
        repo_url='https://prometheus-community.github.io/helm-charts',
        release_name='kube-prometheus-stack',
        namespace='monitoring',
        values=['charts/prometheus/values.yaml'],
        create_namespace=True
    )
    
    # Loki for logs
    helm_remote('loki',
        repo_name='grafana-charts',
        repo_url='https://grafana.github.io/helm-charts',
        release_name='loki',
        namespace='monitoring',
        values=['charts/loki/values.yaml'],
        create_namespace=False
    )
    
    if ENABLE_TRACING:
        # Tempo for traces
        helm_remote('tempo',
            repo_name='grafana-charts',
            repo_url='https://grafana.github.io/helm-charts',
            release_name='tempo',
            namespace='monitoring',
            values=['charts/tempo/values.yaml'],
            create_namespace=False
        )
    
    # Alloy for telemetry collection
    helm_remote('alloy',
        repo_name='grafana-charts',
        repo_url='https://grafana.github.io/helm-charts',
        release_name='alloy',
        namespace='monitoring',
        values=['charts/alloy/values.yaml'],
        create_namespace=False
    )

    # Goldilocks chart (installs VPA when enabled in values)
    helm_remote('goldilocks',
        repo_name='fairwinds-stable',
        repo_url='https://charts.fairwinds.com/stable',
        release_name='goldilocks',
        namespace='goldilocks',
        values=['charts/goldilocks/values.yaml'],
        create_namespace=True
    )

# Deploy infrastructure
deploy_core_infrastructure()
deploy_monitoring_stack()

# --- Application Manifests ---
k8s_yaml([
    'frolf-bot-app-manifests/backend-deployment.yaml',
    'frolf-bot-app-manifests/discord-deployment.yaml',
    'frolf-bot-app-manifests/alloy-otlp-service.yaml',
    'frolf-bot-app-manifests/sysctl-inotify-daemonset.yaml',
    'frolf-bot-app-manifests/ingress.yaml',
])

# --- Resource Configuration ---
def configure_infrastructure_resources():
    """Configure infrastructure resource dependencies and labels."""
    # Core infrastructure
    k8s_resource('my-nats', 
        labels=['infra', 'core'],
        port_forwards=4222
    )
    
    k8s_resource('my-postgresql', 
        labels=['infra', 'core'],
        port_forwards=5432
    )
    
    # Monitoring stack
    if ENABLE_MONITORING:
        k8s_resource('kube-prometheus-stack-grafana', 
            labels=['infra', 'monitoring'],
            port_forwards=['3000:3000'],
            resource_deps=['my-nats', 'my-postgresql']
        )
        
        k8s_resource('loki', 
            labels=['infra', 'monitoring'],
            resource_deps=['kube-prometheus-stack-grafana']
        )
        
        if ENABLE_TRACING:
            k8s_resource('tempo', 
                labels=['infra', 'monitoring'],
                resource_deps=['kube-prometheus-stack-grafana']
            )
        
        k8s_resource('alloy', 
            labels=['infra', 'monitoring'],
            resource_deps=['loki'] + (['tempo'] if ENABLE_TRACING else [])
        )

    # Goldilocks resources (from Helm release)
    k8s_resource('goldilocks-controller', labels=['infra', 'monitoring'])
    k8s_resource('goldilocks-dashboard', labels=['infra', 'monitoring'])

def configure_application_resources():
    """Configure application resource dependencies and labels."""
    base_deps = ['my-nats', 'my-postgresql']
    
    if repo_status['backend']:
        k8s_resource('frolf-bot-backend', 
            resource_deps=base_deps,
            labels=['app', 'backend'],
            port_forwards=['8080:8080']
        )
    
    if repo_status['discord']:
        # Discord bot only depends on infrastructure, not backend
        # This allows Discord to start first and provide the stream that backend needs
        k8s_resource('frolf-bot-discord', 
            resource_deps=base_deps,
            labels=['app', 'discord']
        )

# Configure resources
configure_infrastructure_resources()
configure_application_resources()

# --- File Watching ---
def setup_file_watching():
    """Set up file watching for external repositories."""
    if repo_status['backend']:
        local_resource('watch-frolf-bot',
            'echo "Watching frolf-bot repo for changes"',
            deps=[FROLF_BOT_REPO],
            labels=['watch'],
            allow_parallel=True
        )
    
    if repo_status['discord']:
        local_resource('watch-discord-bot',
            'echo "Watching discord-frolf-bot repo for changes"',
            deps=[DISCORD_BOT_REPO],
            labels=['watch'],
            allow_parallel=True
        )

setup_file_watching()

# --- Development Helpers ---
def create_development_helpers():
    """Create helpful development resources."""
    local_resource('dev-status',
        "bash -lc 'for ns in frolf-bot monitoring nats postgres; do echo \"=== $ns ===\"; kubectl get pods -n \"$ns\" -o wide || true; echo; done'",
        labels=['helpers'],
        allow_parallel=True
    )
    
    local_resource('dev-events',
        "bash -lc 'for ns in frolf-bot monitoring nats postgres; do echo \"=== $ns events (last 30) ===\"; kubectl get events -n \"$ns\" --sort-by=.lastTimestamp | tail -n 30 || true; echo; done'",
        labels=['helpers'],
        allow_parallel=True
    )
    
    local_resource('dev-endpoints',
        "bash -lc 'echo \"=== monitoring services ===\"; kubectl -n monitoring get svc grafana loki alloy -o wide || true; echo; echo \"=== nats services ===\"; kubectl -n nats get svc -o wide || true; echo; echo \"=== postgres services ===\"; kubectl -n postgres get svc -o wide || true; echo; echo \"=== frolf-bot services ===\"; kubectl -n frolf-bot get svc -o wide || true; echo;'",
        labels=['helpers'],
        allow_parallel=True
    )
    
    local_resource('dev-logs',
        'echo "Quick logs: tilt logs <resource-name>"',
        labels=['helpers'],
        allow_parallel=True
    )

    # Quick resource usage audit (kubectl top)
    local_resource('dev-top',
        'bash -lc "chmod +x scripts/dev-top.sh && scripts/dev-top.sh"',
        labels=['helpers', 'audit'],
        allow_parallel=True
    )

    # Restarts overview across namespaces
    local_resource('dev-restarts',
        'bash -lc "chmod +x scripts/dev-restarts.sh && scripts/dev-restarts.sh"',
        labels=['helpers', 'audit'],
        allow_parallel=True
    )
    
    # Database migration helper
    if repo_status['backend']:
        local_resource('db-migrate',
            'echo "Run migrations: kubectl exec -it deployment/frolf-bot-backend -- ./frolf-bot migrate"',
            labels=['helpers'],
            allow_parallel=True
        )

    # Label namespaces for Goldilocks recommendations
    local_resource('goldilocks-label-namespaces',
        'bash -lc "kubectl create ns goldilocks --dry-run=client -o yaml | kubectl apply -f -; \
        kubectl label ns frolf-bot goldilocks.fairwinds.com/enabled=true --overwrite; \
        kubectl label ns monitoring goldilocks.fairwinds.com/enabled=true --overwrite; \
        echo Goldilocks labeled namespaces: $(kubectl get ns -L goldilocks.fairwinds.com/enabled | grep true | awk \'{print $1}\')"',
        labels=['helpers'],
        resource_deps=['goldilocks-controller'],
        allow_parallel=True
    )

    # Quick link/info for Goldilocks dashboard
    local_resource('goldilocks-info',
        'bash -lc "echo \"Goldilocks dashboard: kubectl -n goldilocks port-forward svc/goldilocks-dashboard 8081:80\"; \
        echo \"Then open http://localhost:8081\""',
        labels=['helpers'],
        resource_deps=['goldilocks-dashboard'],
        allow_parallel=True
    )

    # Audit docs pointer
    local_resource('dev-audit-info',
        'bash -lc "chmod +x scripts/dev-audit-info.sh && scripts/dev-audit-info.sh"',
        labels=['helpers', 'audit'],
        allow_parallel=True
    )

create_development_helpers()

# --- Environment Summary ---
def print_environment_summary():
    """Print environment configuration summary."""
    print("🚀 Frolf Bot Development Environment")
    print("=" * 50)
    print("📁 Repositories:")
    for name, status in repo_status.items():
        status_icon = "✅" if status else "❌"
        print("   %s %s" % (status_icon, name))
    
    print("\n🔧 Features:")
    print("   - Monitoring: %s" % ("✅ Enabled" if ENABLE_MONITORING else "❌ Disabled"))
    print("   - Tracing: %s" % ("✅ Enabled" if ENABLE_TRACING else "❌ Disabled"))
    print("   - Profiling: %s" % ("✅ Enabled" if ENABLE_PROFILING else "❌ Disabled"))
    
    print("\n🌐 Access URLs:")
    print("   - Backend API: http://localhost:8080")
    print("   - PostgreSQL: localhost:5432")
    print("   - NATS: localhost:4222")
    if ENABLE_MONITORING:
        print("   - Grafana: http://localhost:3000")
    
    print("\n💡 Quick Commands:")
    print("   - tilt up                    # Start everything")
    print("   - tilt down                  # Stop everything") 
    print("   - tilt logs <resource>       # View logs")
    print("   - tilt trigger <resource>    # Manually trigger rebuild")
    print("=" * 50)

if not IS_TEARDOWN:
    print_environment_summary()

# --- Performance Optimizations ---
# Enable parallel builds for faster startup
set_team('frolf-bot-dev')

# Optimize resource allocation
if not IS_CI:
    # Only enable resource intensive features in local dev
    update_settings(max_parallel_updates=3)

# Watch Tiltfile for changes
watch_file('./Tiltfile')
