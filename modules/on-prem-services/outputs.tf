output "remote_admin_token" {
  description = "The token for the remote admin service account"
  value       = base64decode(data.external.remote_admin_token.result.content)
}

output "remote_kubeconfig" {
  description = "The kubeconfig for the remote Kubernetes cluster"
  value       = data.external.remote_kubeconfig.result.content
}

output "cluster_secret" {
  description = "The remote secret for Istio cluster 2 (on prem)"
  value       = data.external.cluster_secret.result.content
}

output "remote_ingress_ip" {
  description = "The IP address of the ingress gateway"
  value       = data.external.remote_ingress_ip.result.content
}