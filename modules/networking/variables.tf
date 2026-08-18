variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs must be provided."
  }
}

variable "app_subnet_cidrs" {
  description = "CIDRs for application private subnets"
  type        = list(string)

  validation {
    condition     = length(var.app_subnet_cidrs) == 2
    error_message = "Exactly two application subnet CIDRs must be provided."
  }
}

variable "database_subnet_cidrs" {
  description = "CIDRs for database private subnets"
  type        = list(string)

  validation {
    condition     = length(var.database_subnet_cidrs) == 2
    error_message = "Exactly two database subnet CIDRs must be provided."
  }
}

variable "app_port" {
  description = "Port exposed by the application"
  type        = number
  default     = 80
}