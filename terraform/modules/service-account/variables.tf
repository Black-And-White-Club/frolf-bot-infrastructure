// DEPRECATED: variables moved along with module implementation to
// all-infrastructure/terraform/modules/service-account
// Project-level variable values (tfvars) should remain in each project.
// Remove this file after verifying no local callers reference it.

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI compartment OCID where identity objects will be created"
  type        = string
  default     = ""
}

variable "service_account_id" {
  description = "Logical name to use for the application user in OCI"
  type        = string
  default     = "frolf-bot-service-account"
}

variable "aiu_service_account_id" {
  description = "Logical name for the AIU user in OCI"
  type        = string
  default     = "frolf-bot-aiu"
}
