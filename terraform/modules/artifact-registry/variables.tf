variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "service_account_email" {
  description = "The email of the service account to grant access"
  type        = string
}
