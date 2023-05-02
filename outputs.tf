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
  sensitive   = true
}

output "yba_ui_ip" {
  value       = module.cloud_services.yba_ui_ip
  description = "The IP address of the YBA UI"
}

output "remote_ingress_ip" {
  description = "The IP address of the ingress gateway for the remote cluster"
  value       = module.on_prem_services.remote_ingress_ip
}
