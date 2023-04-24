output "cluster_secret" {
  description = "The remote secret for Istio cluster"
  value       = data.external.cluster_secret.result.content
}

output "open_yba_ui" {
  value       = module.yba.open_yba_ui
  description = "The YBA UI"
}