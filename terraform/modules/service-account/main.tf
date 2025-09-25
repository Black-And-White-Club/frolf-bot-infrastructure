resource "google_service_account" "frolf_bot_sa" {
  account_id   = "frolf-bot-service-account"
  display_name = "Frolf Bot Service Account"
  description  = "Service account for frolf bot application"
}

resource "google_service_account" "aiu_sa" {
  account_id   = "frolf-bot-aiu-service-account"
  display_name = "Frolf Bot AIU Service Account"
  description  = "Service account for ArgoCD Image Updater to read from registry"
}

output "service_account_email" {
  description = "The email of the frolf bot service account"
  value       = google_service_account.frolf_bot_sa.email
}

output "service_account_name" {
  description = "The name of the frolf bot service account"
  value       = google_service_account.frolf_bot_sa.name
}

output "aiu_service_account_email" {
  description = "The email of the AIU service account"
  value       = google_service_account.aiu_sa.email
}

output "aiu_service_account_name" {
  description = "The name of the AIU service account"
  value       = google_service_account.aiu_sa.name
}
