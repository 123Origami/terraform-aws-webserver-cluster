# these are all configurable modules for the project

variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type        = string
  # No default, must be defined by the provider
}

variable "instance_type" {
  description = "EC2 instance to be used for the webservers"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "minimum number of serves to be deployed"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of servers to be deployed"
  type        = number
  default     = 5
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}
variable "server_port" {
  description = "Port the web server listens on for HTTP traffic"
  type        = number
  default     = 80
}

variable "ssh_port" {
  description = "SSH port for access"
  type        = number
  default     = 22
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to the instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "environment" {
  description = "Environment name (dev, staging, production) - used for tagging"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

# addition for version 2 tagging

variable "custom_user_data" {
  description = "Custom user data script for instances (optional)"
  type        = string
  default     = ""
}
