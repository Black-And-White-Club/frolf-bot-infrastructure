resource "google_artifact_registry_repository" "frolf_bot_repo" {
  location      = var.region
  repository_id = "frolf-bot"
  description   = "Docker repository for frolf bot application"
  format        = "DOCKER"
}

# service account permissions to push/pull from Artifact Registry
resource "google_artifact_registry_repository_iam_member" "frolf_bot_sa_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.frolf_bot_repo.location
  repository = google_artifact_registry_repository.frolf_bot_repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.service_account_email}"
}
