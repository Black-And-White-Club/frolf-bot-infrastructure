output "repository_url" {
  description = "The URL of the artifact registry repository"
  value       = google_artifact_registry_repository.frolf_bot_repo.name
}
