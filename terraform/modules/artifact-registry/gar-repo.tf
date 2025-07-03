resource "google_artifact_registry_repository" "frolf_bot_repo" {
  location      = var.region
  repository_id = "frolf-bot"
  description   = "Docker repository for frolf bot application"
  format        = "DOCKER"
}
