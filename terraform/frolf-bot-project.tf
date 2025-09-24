# Frolf Bot Project Infrastructure
# This file defines the main infrastructure components for the frolf bot project

module "service_account" {
  source     = "./modules/service-account"
  project_id = var.project_id
}

module "artifact_registry" {
  source     = "./modules/artifact-registry"
  project_id = var.project_id
  region     = var.region
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
