#!/usr/bin/env bash
set -euo pipefail

echo "=== Nodes (kubectl top) ==="
kubectl top nodes || true
echo

for ns in frolf-bot monitoring nats postgres; do
  echo "=== ${ns} pods by CPU ==="
  kubectl top pod -n "${ns}" --sort-by=cpu || true
  echo
  echo "=== ${ns} pods by MEM ==="
  kubectl top pod -n "${ns}" --sort-by=memory || true
  echo
done
