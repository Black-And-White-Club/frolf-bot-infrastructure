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

variable "aiu_service_account_email" {
  description = "The email of the AIU service account"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI compartment OCID where repository should be created"
  type        = string
  default     = ""
}

variable "tenancy_namespace" {
  description = "OCI tenancy namespace used for OCIR (the namespace part of repository URL)"
  type        = string
  default     = ""
}

variable "repo_name" {
  description = "The repository name to create in OCIR"
  type        = string
  default     = "frolf-bot"
}

// DEPRECATED: artifact-registry variables moved to centralized module
// Keep per-project tfvars (values) in the project repo; implementation is now
// held in: all-infrastructure/terraform/modules/artifact-registry
