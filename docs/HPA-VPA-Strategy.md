# HPA & VPA Strategy

Guidance for using Horizontal Pod Autoscaler (HPA) and Vertical Pod Autoscaler (VPA) together.

## Do/Don't
- Do: Use VPA in "recommend" mode (Goldilocks) for sizing guidance.
- Do: Use HPA to scale replicas for bursty traffic or CPU-bound work.
- Don't: Run VPA and HPA on the same target in conflicting modes (VPA update/auto can fight HPA).

## When to use HPA
- CPU-bound or request-driven workloads with variable traffic.
- Memory is steady but CPU spikes: use HPA on CPU.
- If you have RPS/queue depth metrics, prefer a custom metric HPA.

## HPA Targets
- CPU percentage (of requests) is simple and effective.
- Example target: 70% CPU -> HPA maintains average CPU usage ~0.7 × requests across replicas.

## Custom Metric Examples
- NATS consumer lag (if exported) as a scale signal.
- HTTP RPS or p95 latency (careful with feedback loops).

## Example HPA (CPU)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: discord-bot
  namespace: frolf-bot
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frolf-bot-discord
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Rollout Tips
- Ensure requests are set before enabling HPA.
- Validate with load bursts and check for thrashing.
- Use PDBs and readiness probes for graceful scaling.
