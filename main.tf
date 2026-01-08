module "frontend" {
  source = "./frontend"
  providers = { aws = aws.frontend }

  project_name     = var.project_name
  vpc_cidr         = var.frontend_vpc_cidr
  instance_type    = var.instance_type
  ssh_allowed_cidr = var.ssh_allowed_cidr
  backend_url = module.backend.backend_private_ip
}

module "backend" {
  source = "./backend"
  providers = { aws = aws.backend }

  project_name     = var.project_name
  vpc_cidr         = var.backend_vpc_cidr
  instance_type    = var.instance_type
  ssh_allowed_cidr = var.ssh_allowed_cidr
}

module "peering" {
  source = "./peering"

  providers = {
    aws.frontend = aws.frontend
    aws.backend  = aws.backend
  }

  frontend_vpc_id = module.frontend.vpc_id
  backend_vpc_id  = module.backend.vpc_id

  frontend_rt_id  = module.frontend.route_table_id
  backend_rt_id   = module.backend.route_table_id

  frontend_cidr   = var.frontend_vpc_cidr
  backend_cidr    = var.backend_vpc_cidr
}
resource "aws_security_group_rule" "frontend_to_backend_5000" {
  provider          = aws.backend
  type              = "ingress"
  from_port         = 5000
  to_port           = 5000
  protocol          = "tcp"

  security_group_id = module.backend.backend_sg_id
  cidr_blocks       = [var.frontend_vpc_cidr]
}
