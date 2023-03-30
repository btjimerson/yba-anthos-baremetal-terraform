output "nginx_ingress_ip" {
  value       = data.local_file.nginx_ingress_ip.content
  description = "The IP address of the nginx ingress controller"
}

