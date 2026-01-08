resource "aws_route" "front_to_back" {
  provider = aws.frontend

  route_table_id            = var.frontend_rt_id
  destination_cidr_block    = var.backend_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "back_to_front" {
  provider = aws.backend

  route_table_id            = var.backend_rt_id
  destination_cidr_block    = var.frontend_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
