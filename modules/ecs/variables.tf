variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for ECS container instances"
  type        = string
  default     = "t3.micro"
}

variable "public_subnet_ids" {
  description = "Subnets where ECS EC2 instances will run"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security Group assigned to ECS EC2 instances"
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}