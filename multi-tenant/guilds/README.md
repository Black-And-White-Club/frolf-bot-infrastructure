# Example guild configurations
# Each file represents a guild and its configuration
# The ApplicationSet will read these files and create applications automatically

# To add a new guild:
# 1. Create a new YAML file in this directory (e.g., guild-123456789.yaml)
# 2. Define the guild configuration using the template below
# 3. Commit and push to trigger ArgoCD sync

# Template for a new guild file:
# guild_id: "123456789"
# tier: "free"  # or "pro"
# discord_memory_request: "64Mi"
# discord_memory_limit: "128Mi"
# discord_cpu_request: "50m"
# discord_cpu_limit: "100m"
# backend_memory_request: "128Mi"
# backend_memory_limit: "256Mi"
# backend_cpu_request: "100m"
# backend_cpu_limit: "200m"
