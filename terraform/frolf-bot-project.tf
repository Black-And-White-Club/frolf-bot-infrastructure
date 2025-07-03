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

module "cloud_engine" {
  source     = "./modules/cloud-engine"
  project_id = var.project_id
  region     = var.region
  zone       = var.zone
}
