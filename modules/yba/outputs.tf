output "open_yba_ui" {
  value       = "open http://${data.external.yba_ui_ip.result.content}/"
  description = "The IP address of the YBA UI"
}
