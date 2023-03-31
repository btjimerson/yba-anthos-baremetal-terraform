output "yba_ui_ip" {
  value       = data.local_file.yba_ui_ip.content
  description = "The IP address of the YBA UI"
}
