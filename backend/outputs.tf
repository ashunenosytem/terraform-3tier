output "vpc_id" { value = aws_vpc.this.id }
output "route_table_id" {
  value = aws_route_table.private_rt.id
}
output "backend_private_ip" {
  value = aws_instance.backend.private_ip
}

output "database_private_ip" {
  value = aws_instance.database.private_ip
}

output "backend_sg_id" {
  value = aws_security_group.backend_sg.id
}

output "db_sg_id" {
  value = aws_security_group.db_sg.id
}
