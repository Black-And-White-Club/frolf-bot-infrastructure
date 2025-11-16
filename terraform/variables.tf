variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "compartment_ocid" {
  description = "OCI compartment OCID for volumes"
  type        = string
  default     = ""
}

variable "availability_domain" {
  description = "Default OCI availability domain to use for volumes"
  type        = string
  default     = ""
}

variable "tenancy_namespace" {
  description = "OCI tenancy namespace for OCIR (used to build repository URL)"
  type        = string
  default     = "<your-tenancy-namespace>"
}

variable "repo_name" {
  description = "Artifact repository name to create in OCIR"
  type        = string
  default     = "frolf-bot"
}
