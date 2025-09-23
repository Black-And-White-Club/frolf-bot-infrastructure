# Resource Usage Audit (Quick Guide)

Use this checklist to capture current CPU/memory usage, restarts, and throttling. Do this over a representative period of load.

## 1) Quick snapshots

- Nodes summary:
  - `kubectl top nodes`
- Pods by CPU/MEM (per namespace):
  - `kubectl top pod -n frolf-bot --sort-by=cpu`
  - `kubectl top pod -n frolf-bot --sort-by=memory`
  - Repeat for `monitoring`, `nats`, `postgres`
- Restarts overview:
  - `kubectl get pods -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount | sort -k3 -nr | head -n 30`

## 2) Prometheus spot checks (Grafana PromQL or /api/v1/query)

Replace `namespace="frolf-bot"` and pod names as needed.

- CPU usage (container):
  - `rate(container_cpu_usage_seconds_total{namespace="frolf-bot", container!=""}[5m])`
- CPU throttling ratio (lower is better):
  - `sum(rate(container_cpu_cfs_throttled_periods_total{namespace="frolf-bot"}[5m])) / sum(rate(container_cpu_cfs_periods_total{namespace="frolf-bot"}[5m]))`
- Memory working set (bytes):
  - `container_memory_working_set_bytes{namespace="frolf-bot", container!=""}`
- OOM kills:
  - `increase(kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}[1d])`
- Restarts (last 24h):
  - `increase(kube_pod_container_status_restarts_total{namespace="frolf-bot"}[24h])`

Note: Metric names may vary by stack; if using kube-prometheus-stack, prefer `container_cpu_usage_seconds_total` and `kube_pod_container_*` families. For cAdvisor deprecations, fall back to `node_namespace_pod_container:*` aggregates.

## 3) Golden signals for each app

- Discord bot:
  - P99 CPU: `histogram_quantile(0.99, sum by (le) (rate(container_cpu_usage_seconds_total{pod=~"frolf-bot-discord.*"}[5m])))`
  - Goroutines: scrape pprof `/debug/pprof/goroutine?debug=1` if enabled.
- Backend:
  - DB saturation: compare `pg_stat_activity` active vs max connections if exported.
  - NATS lag (if exposed): consumer lag metrics or event queue depth.

## 4) Capture peaks

- During a burst, record `kubectl top pod` output +/- 5 minutes around the event.
- Save pprof snapshots for hotspots:
  - CPU (30s): `go tool pprof -seconds 30 http://localhost:6060/debug/pprof/profile`
  - Heap: `go tool pprof http://localhost:6060/debug/pprof/heap`

## 5) Summarize

Fill this table per deployment:

- Deployment: <name>
- Baseline CPU: <mCPU avg/p95>
- Peak CPU: <mCPU p99>
- Baseline MEM: <MiB avg/p95>
- Peak MEM: <MiB p99>
- Restarts: <count window>
- Throttling: <ratio>
- Notes: <hotspots, leaks, spikes>
