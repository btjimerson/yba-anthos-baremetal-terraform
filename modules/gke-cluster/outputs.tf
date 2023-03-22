output "cluster_id" {
  description = "The cluster's ID"
  value       = google_container_cluster.primary.id
}

output "endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "The CA certificate for the GKE cluster"
  value       = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
}
