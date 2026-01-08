
variable "vpc_cidr" {
  type = string
}

variable "project_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "ssh_allowed_cidr" {
  type = string
}
variable "backend_url" {
  type = string
}

# variable "backend_private_ip" {
#   type = string
# }
