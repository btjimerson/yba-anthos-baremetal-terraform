output "cloud_cluster_ca_cert" {
  description = "The CA cert for the cloud cluster"
  value       = data.external.cloud_cluster_ca_cert.result.content
}
output "cloud_cluster_ca_key" {
  description = "The CA key for the cloud cluster"
  value       = data.external.cloud_cluster_ca_key.result.content
}
output "cloud_cluster_root_cert" {
  description = "The root cert for the cloud cluster"
  value       = data.external.cloud_cluster_root_cert.result.content
}
output "cloud_cluster_cert_chain" {
  description = "The CA cert for the cloud cluster"
  value       = data.external.cloud_cluster_cert_chain.result.content
}
output "on_prem_cluster_ca_cert" {
  description = "The CA cert for the on-prem cluster"
  value       = data.external.on_prem_cluster_ca_cert.result.content
}
output "on_prem_cluster_ca_key" {
  description = "The CA key for the on-prem cluster"
  value       = data.external.on_prem_cluster_ca_key.result.content
}
output "on_prem_cluster_root_cert" {
  description = "The root cert for the on-prem cluster"
  value       = data.external.on_prem_cluster_root_cert.result.content
}
output "on_prem_cluster_cert_chain" {
  description = "The CA cert for the on-prem cluster"
  value       = data.external.on_prem_cluster_cert_chain.result.content
}