// DEPRECATED: cloud-engine variables moved to centralized module.
// Project-level tfvars with deployment values should remain in the project repo
// (for example: compartment OCID, availability domain, image IDs). Remove this
// file once all references are migrated to the shared module.

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "zone" {
  description = "The GCP zone"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI compartment OCID for migration target"
  type        = string
  default     = ""
}

variable "availability_domain" {
  description = "OCI availability domain"
  type        = string
  default     = ""
}

variable "image_id" {
  description = "OCI image OCID to use for instances"
  type        = string
  default     = ""
}

variable "shape" {
  description = "OCI instance shape"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
  default     = ""
}

variable "vcn_cidr" {
  description = "VCN CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}
