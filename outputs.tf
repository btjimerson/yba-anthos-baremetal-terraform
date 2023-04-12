output "ssh_command_for_pnap" {
  value       = module.baremetal_anthos_cluster.ssh_command
  description = "Command to run to SSH into the bastion host"
}

output "remote_admin_token" {
  description = "The token for the remote admin service account"
  value       = module.on_prem_services.remote_admin_token
}

output "remote_kubeconfig" {
  description = "The kubeconfig for the remote Kubernetes cluster"
  value       = module.on_prem_services.remote_kubeconfig
}

output "nginx_ingress_ip" {
  value       = module.cloud_services.nginx_ingress_ip
  description = "The IP address of the nginx ingress controler"
}

output "yba_ui_ip" {
  value       = module.cloud_services.yba_ui_ip
  description = "The IP address of the YBA UI"
}

output "cluster1_secret" {
  description = "The remote secret for Istio cluster 1 (GKE)"
  value       = module.cloud_services.cluster1_secret
}

output "cluster2_secret" {
  description = "The remote secret for Istio cluster 1 (on prem)"
  value       = module.on_prem_services.cluster2_secret
}