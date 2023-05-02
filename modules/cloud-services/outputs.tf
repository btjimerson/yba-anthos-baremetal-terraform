output "cluster_secret" {
  description = "The remote secret for Istio cluster"
  value       = data.external.cluster_secret.result.content
}

output "yba_ui_ip" {
  value       = module.yba.yba_ui_ip
  description = "The IP address of the YBA UI"
}