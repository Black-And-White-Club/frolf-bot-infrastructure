# Right-Sizing Requests & Limits

Use audit findings to set pragmatic CPU/memory requests and limits.

## Principles
- Requests cover steady-state p95 plus headroom (20–50%).
- Limits avoid unnecessary throttling; 2–4x requests for bursty EDA workloads.
- Prefer no memory limit if GC spikes are expected; otherwise set 1.5–2x working set.
- Keep monitoring and revisit regularly (Goldilocks recs help).

## Workflow
1) Start from Goldilocks recommendations (requests) for each container.
2) Compare with observed usage (avg/p95/p99) from Prometheus.
3) Choose request = max(Goldilocks, observed p95) × headroom.
4) Choose limit_CPU ≈ 2–4 × request_CPU (EDA -> closer to 4x if bursts).
5) Choose limit_MEM = 1.5–2 × working set p95, or unset if safe.
6) Apply and observe throttle/OOM/restarts; adjust iteratively.

## Example
- Discord bot:
  - Observed p95 CPU: 60m; Goldilocks suggests 50m.
  - Request_CPU: 60m × 1.3 ≈ 80m (round to 100m if desired).
  - Limit_CPU: 3 × 100m = 300m.
  - Working set p95: 110Mi → Request_MEM: 128Mi; Limit_MEM: 256–384Mi.

## Implementation Tips
- Use distinct `resources` per container; keep YAML minimal.
- Align autoscalers with requests (HPA scales on CPU% of requests).
- Verify with `kubectl describe hpa` and Prometheus throttle metrics.

## Post-Change Checks
- CPU throttling ratio < 5% sustained.
- No OOMKilled events.
- Latency/SLOs maintained during bursts.
