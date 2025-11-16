# Frolf Bot Project Infrastructure
# This file defines the main infrastructure components for the frolf bot project

module "service_account" {
  # Switch the module source to the central shared repo for migration.
  # For local testing you can use a relative path instead of the git source:
  # source = "../all-infrastructure/terraform/modules/service-account"
  source           = "git::ssh://git@github.com/YOUR_ORG/all-infrastructure.git//terraform/modules/identity-users?ref=migrate-service-account"
  compartment_ocid = var.compartment_ocid
}

module "artifact_registry" {
  source            = "git::ssh://git@github.com/YOUR_ORG/all-infrastructure.git//terraform/modules/container-registry?ref=migrate-service-account"
  compartment_ocid  = var.compartment_ocid
  tenancy_namespace = var.tenancy_namespace
  repo_name         = var.repo_name
}

// Persistent disks for frolf-bot storage
// Migrated to the shared `disks` module in the central infra repo.
// IMPORTANT: to avoid resource recreation, perform the `terraform state mv` commands
// described in `terraform/modules/disks/README.md` before running `terraform apply`.
module "disks" {
  source                      = "git::ssh://git@github.com/YOUR_ORG/all-infrastructure.git//terraform/modules/block-storage?ref=migrate-service-account"
  compartment_ocid            = var.compartment_ocid
  default_availability_domain = var.availability_domain
  disks = {
    frolf_bot_postgres_disk = {
      name                = "frolf-bot-postgres-disk"
      size                = 10
      availability_domain = var.availability_domain
      labels              = { environment = "frolf-bot" }
    }
    frolf_bot_grafana_disk = {
      name                = "frolf-bot-grafana-disk"
      size                = 10
      availability_domain = var.availability_domain
      labels              = { environment = "frolf-bot" }
    }
  }
}

# Workload Identity Federation for secure auth
// Migration placeholder: GCP Workload Identity resources have been removed.
// Use the central `github-oidc` module to track migration progress and
// provide a stable surface while you create an equivalent OIDC provider and
// dynamic-group/policy in OCI that grants GitHub Actions the necessary
// permissions for CI/CD operations.
module "github_oidc" {
  source = "git::ssh://git@github.com/YOUR_ORG/all-infrastructure.git//terraform/modules/github-oidc?ref=migrate-service-account"

  # Provide context for the migration (owner/org) so maintainers know which
  # GitHub repositories should be granted access when creating OCI policies.
  owner = "Black-And-White-Club"
  repo  = "frolf-bot"
}
