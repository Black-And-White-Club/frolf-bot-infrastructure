#!/usr/bin/env bash
set -euo pipefail

for ns in frolf-bot monitoring nats postgres; do
  echo "=== ${ns} restarts (top 20) ==="
  kubectl get pods -n "${ns}" \
    -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount \
    --no-headers | awk '{print $1","$2}' | sort -t, -k2 -nr | head -n 20 || true
  echo
done
