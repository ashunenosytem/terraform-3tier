module "frontend" {
  source = "./frontend"
  providers = { aws = aws.frontend }

  project_name     = var.project_name
  vpc_cidr         = var.frontend_vpc_cidr
  instance_type    = var.instance_type
  ssh_allowed_cidr = var.ssh_allowed_cidr
  backend_private_ip = module.backend.backend_private_ip
  backend-alb-dns =  aws_lb.backend-alb.dns_name
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
# resource "aws_security_group_rule" "frontend_to_backend_5000" {
#   provider          = aws.backend
#   type              = "ingress"
#   from_port         = 5000
#   to_port           = 5000
#   protocol          = "tcp"

#   security_group_id = module.backend.backend_sg_id
#   cidr_blocks       = [var.frontend_vpc_cidr]
# }

resource "aws_lb" "backend-alb" {
  name = "backend-alb"
  load_balancer_type               = "application"
  internal           = true
  security_groups    = [module.backend.backend_sg_id]
  
  subnets = [
    module.backend.private_subnet_id,
    module.backend.private_subnet_id1
  ]
}

resource "aws_lb" "frontend-alb" {
  provider = aws.frontend
  name = "frontend-alb"
  load_balancer_type               = "application"
  internal           = false
  security_groups    = [module.frontend.frontend_sg_id]
  
  subnets = [
    module.frontend.public_subnet_id,
    module.frontend.public_subnet_id1
  ]
}
resource "aws_lb_target_group" "backend-instances" {
  name     = "backend-instances"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.backend.vpc_id
}
resource "aws_lb_target_group" "frontend-instances" {
  provider = aws.frontend
  name     = "frontend-instances"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.frontend.vpc_id
}
resource "aws_launch_template" "backend-template"{
  image_id      = "ami-001e143664a9c8669"
  instance_type = "t3.micro"
  key_name                             = "bastionNew" 
  description                          = "1.0"
  vpc_security_group_ids = [module.backend.backend_sg_id]
}
resource "aws_launch_template" "frontend-template"{
  provider = aws.frontend
  image_id      = "ami-0e0b5706975a5d90b"
  instance_type = "t3.micro"
  description                          = "1.0"
  vpc_security_group_ids = [module.frontend.frontend_sg_id]
}
resource "aws_autoscaling_group" "backend-scaling"{
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  force_delete = false
  force_delete_warm_pool = false
  ignore_failed_scaling_activities = false
  wait_for_capacity_timeout = "10m"
  vpc_zone_identifier  = [module.backend.private_subnet_id, module.backend.private_subnet_id1]
  launch_template {
    id      = aws_launch_template.backend-template.id
    version = "$Default"
  }
}
resource "aws_autoscaling_group" "frontend-scaling"{
  provider = aws.frontend
  
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  vpc_zone_identifier  = [module.frontend.public_subnet_id,
    module.frontend.public_subnet_id1]
  launch_template {
    id      = aws_launch_template.frontend-template.id
    version = "$Default"
  }
}