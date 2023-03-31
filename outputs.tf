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

output "website" {
  value       = "https://${var.domain_name}"
  description = "The domain the website will be hosted on."
}

output "nginx_ingress_ip" {
  value       = module.inlets_uplink.nginx_ingress_ip
  description = "The IP address of the nginx ingress controler"
}

output "yba_ui_ip" {
  value       = module.yba.yba_ui_ip
  description = "The IP address of the YBA UI"
}
