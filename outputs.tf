output "backend_database_private_ip" {
  description = "Private IP of backend database EC2"
  value       = module.backend.database_private_ip
}
