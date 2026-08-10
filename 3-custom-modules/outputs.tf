output "web_server_ip" {
  description = "Public IP of Web Server"
  value       = module.web_server.public_ip
}

output "app_server_ip" {
  description = "Public IP of App Server"
  value       = module.app_server.public_ip
}