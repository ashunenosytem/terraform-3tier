resource "aws_vpc_peering_connection" "peer" {
  provider = aws.frontend

  vpc_id        = var.frontend_vpc_id
  peer_vpc_id   = var.backend_vpc_id
  peer_region   = "ap-south-1"

  auto_accept = false
}

resource "aws_vpc_peering_connection_accepter" "accept" {
  provider = aws.backend

  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true
}
