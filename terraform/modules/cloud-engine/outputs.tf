// DEPRECATED: outputs for cloud-engine are provided by the central module
// at all-infrastructure/terraform/modules/cloud-engine. This placeholder was
// left to indicate the module was moved and avoid accidental local use.

output "instance_self_link" {
  description = "Compatibility: maps to OCI instance OCID (was GCP self_link)"
  value       = module.cloud_engine_shared.instance_ocid
}

output "network_name" {
  description = "Compatibility: maps to OCI VCN OCID"
  value       = module.cloud_engine_shared.vcn_id
}

output "subnetwork_self_link" {
  description = "Compatibility: maps to OCI subnet OCID"
  value       = module.cloud_engine_shared.subnet_id
}
