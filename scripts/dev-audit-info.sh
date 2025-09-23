#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
See docs for audit and sizing guidance:
 - docs/Resource-Audit.md
 - docs/Right-Sizing.md
 - docs/HPA-VPA-Strategy.md
Grafana: http://localhost:3000 (default creds: admin/prom-operator)
EOF
