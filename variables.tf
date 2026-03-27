# variables.tf - All configurable inputs for the module

# ============================================
# REQUIRED VARIABLES
# ============================================

variable "cluster_name" {
  description = "The name to use for all cluster resources (ALB, ASG, SG, etc.)"
  type        = string
  # No default - this MUST be provided by the caller
}

# ============================================
# COMPUTE CONFIGURATION
# ============================================

variable "instance_type" {
  description = "EC2 instance type for the web servers. Use t3.micro for dev, t3.medium for production"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 5
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

# ============================================
# NETWORK CONFIGURATION
# ============================================

variable "server_port" {
  description = "Port the web server listens on for HTTP traffic"
  type        = number
  default     = 80
}

variable "ssh_port" {
  description = "SSH port for debugging access"
  type        = number
  default     = 22
}

# ============================================
# ENVIRONMENT CONFIGURATION
# ============================================

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

# ============================================
# SECURITY CONFIGURATION
# ============================================

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to the instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ============================================
# DAY 10: LOOPS AND CONDITIONALS VARIABLES
# ============================================

variable "enable_autoscaling" {
  description = "Enable autoscaling policies for the cluster (scale out/in)"
  type        = bool
  default     = true
}

variable "additional_sg_rules" {
  description = "Additional security group rules to add to instances (uses for_each)"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {}
}

variable "enable_ssh" {
  description = "Enable SSH access to instances (uses count to make optional)"
  type        = bool
  default     = true
}

variable "custom_instance_tags" {
  description = "Additional tags to add to instances (merged with base tags)"
  type        = map(string)
  default     = {}
}

# ============================================
# USER DATA CONFIGURATION
# ============================================

variable "custom_user_data" {
  description = "Custom user data script for instances (overrides default if provided)"
  type        = string
  default     = ""
}
