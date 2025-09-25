# Frolf Bot Project Infrastructure
# This file defines the main infrastructure components for the frolf bot project

module "service_account" {
  source     = "./modules/service-account"
  project_id = var.project_id
}

module "artifact_registry" {
  source                = "./modules/artifact-registry"
  project_id            = var.project_id
  region                = var.region
  service_account_email = module.service_account.service_account_email
}

# Persistent disks for frolf-bot storage
resource "google_compute_disk" "frolf_bot_postgres_disk" {
  name = "frolf-bot-postgres-disk"
  type = "pd-standard"
  zone = var.zone
  size = 10
  labels = {
    environment = "frolf-bot"
  }
}

resource "google_compute_disk" "frolf_bot_grafana_disk" {
  name = "frolf-bot-grafana-disk"
  type = "pd-standard"
  zone = var.zone
  size = 10
  labels = {
    environment = "frolf-bot"
  }
}

# Workload Identity Federation for secure auth
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }
  attribute_condition = "assertion.repository_owner == 'Black-And-White-Club'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow the pool to impersonate the service account
resource "google_service_account_iam_member" "github_sa_impersonation" {
  service_account_id = module.service_account.service_account_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/Black-And-White-Club/frolf-bot"
}

resource "google_service_account_iam_member" "discord_github_sa_impersonation" {
  service_account_id = module.service_account.service_account_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/Black-And-White-Club/discord-frolf-bot"
}
