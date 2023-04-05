output "ssh_command_for_pnap" {
  value       = module.baremetal_anthos_cluster.ssh_command
  description = "Command to run to SSH into the bastion host"
}

output "ssh_key_path" {
  value       = module.baremetal_anthos_cluster.ssh_key_path
  description = "Path to the SSH Private key for the bastion host"
}

output "pnap_bastion_host_ip" {
  value       = module.baremetal_anthos_cluster.bastion_host_ip
  description = "IP Address of the bastion host in the test environment"
}

output "pnap_bastion_host_username" {
  value       = module.baremetal_anthos_cluster.bastion_host_username
  description = "Username for the bastion host in the test environment"
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
  value       = module.yba.yba_ui_ip
  description = "The IP address of the YBA UI"
}
