# Cluster resources (frolf-bot)

This directory contains cluster-level Kubernetes manifests for frolf-bot. Historically this folder contained static hostPath PV manifests for local development.

Best practices (production):

- Use PVCs with dynamic provisioning (StorageClass: `oci-block-storage`).
- Do not check-in hostPath PV manifests for production clusters.
- Backup data before migrating or deleting existing local volumes.
