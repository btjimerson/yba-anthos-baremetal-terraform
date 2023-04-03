output "nginx_ingress_ip" {
  value       = data.external.nginx_ingress_ip.result.content
  description = "The IP address of the nginx ingress controller"
}

