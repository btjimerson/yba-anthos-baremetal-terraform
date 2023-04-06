output "nginx_ingress_ip" {
  value       = data.external.nginx_ingress_ip.result.content
  description = "The IP address of the nginx ingress controller"
}

output "cluster1_secret" {
  description = "The remote secret for Istio cluster 1 (on prem)"
  value       = data.external.cluster1_secret.result.content
}

output "yba_ui_ip" {
  value       = module.yba.yba_ui_ip
  description = "The IP address of the YBA UI"
}