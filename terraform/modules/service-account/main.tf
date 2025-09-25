resource "google_service_account" "frolf_bot_sa" {
  account_id   = "frolf-bot-service-account"
  display_name = "Frolf Bot Service Account"
  description  = "Service account for frolf bot application"
}

output "service_account_email" {
  description = "The email of the frolf bot service account"
  value       = google_service_account.frolf_bot_sa.email
}

output "service_account_name" {
  description = "The name of the frolf bot service account"
  value       = google_service_account.frolf_bot_sa.name
}
