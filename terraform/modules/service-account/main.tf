resource "google_service_account" "frolf_bot_sa" {
  account_id   = "frolf-bot-service-account"
  display_name = "Frolf Bot Service Account"
  description  = "Service account for frolf bot application"
}
