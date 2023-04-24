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

output "open_yba_ui" {
  value       = module.cloud_services.open_yba_ui
  description = "The YBA UI"
}
