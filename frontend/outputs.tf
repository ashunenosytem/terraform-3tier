output "vpc_id" {
  value = aws_vpc.frontend.id
}

output "route_table_id" {
  value = aws_route_table.rt.id
}

output "security_group_id" {
  value = aws_security_group.frontend_sg.id
}
output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}
output "frontend_sg_id" {
  value = aws_security_group.frontend_sg.id
}
