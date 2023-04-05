output "yba_ui_ip" {
  value       = data.external.yba_ui_ip.result.content
  description = "The IP address of the YBA UI"
}
