# main.tf - The actual infrastructure resources

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources - fetch dynamic AWS information
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Random ID for unique bucket names
resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================
# SECURITY GROUP FOR LOAD BALANCER
# ============================================

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-alb-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================
# SECURITY GROUP FOR EC2 INSTANCES
# ============================================

resource "aws_security_group" "instance" {
  name        = "${var.cluster_name}-instance-sg"
  description = "Security group for EC2 instances"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "${var.cluster_name}-instance-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================
# SECURITY GROUP RULES (Refactored with loops)
# ============================================

# Rule 1: HTTP from ALB (always present)
resource "aws_security_group_rule" "allow_http_from_alb" {
  type                     = "ingress"
  from_port                = var.server_port
  to_port                  = var.server_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instance.id
  source_security_group_id = aws_security_group.alb.id
  description              = "HTTP from ALB"
}

# Rule 2: SSH access (optional - can be disabled)
resource "aws_security_group_rule" "allow_ssh" {
  count = var.enable_ssh ? 1 : 0

  type              = "ingress"
  from_port         = var.ssh_port
  to_port           = var.ssh_port
  protocol          = "tcp"
  cidr_blocks       = var.ssh_cidr_blocks
  security_group_id = aws_security_group.instance.id
  description       = "SSH access"
}

# Rule 3: Additional custom rules (for_each loop)
resource "aws_security_group_rule" "additional" {
  for_each = var.additional_sg_rules

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.instance.id
  description       = each.value.description
}

# ============================================
# LAUNCH TEMPLATE (with custom tags)
# ============================================

resource "aws_launch_template" "web" {
  name_prefix            = "${var.cluster_name}-lt-"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = var.custom_user_data != "" ? var.custom_user_data : base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    
    cat > /var/www/html/index.html << HTML
    <!DOCTYPE html>
    <html>
    <head><title>${var.cluster_name}</title></head>
    <body>
        <h1>🚀 ${var.cluster_name}</h1>
        <p>Instance: $INSTANCE_ID</p>
        <p>AZ: $AZ</p>
        <p>Environment: ${var.environment}</p>
    </body>
    </html>
    HTML
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name        = "${var.cluster_name}-instance"
        Environment = var.environment
        ManagedBy   = "Terraform"
      },
      var.custom_instance_tags
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================
# APPLICATION LOAD BALANCER
# ============================================

resource "aws_lb" "web" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

  enable_cross_zone_load_balancing = true

  tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
    ManagedBy   = "Terraform"
  }
}

# ============================================
# TARGET GROUP
# ============================================

resource "aws_lb_target_group" "web" {
  name     = "${var.cluster_name}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
    ManagedBy   = "Terraform"
  }
}

# ============================================
# LISTENER
# ============================================

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = var.server_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ============================================
# AUTO SCALING GROUP
# ============================================

resource "aws_autoscaling_group" "web" {
  name                      = "${var.cluster_name}-asg"
  vpc_zone_identifier       = data.aws_subnets.default.ids
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================
# AUTO SCALING POLICIES (Optional with count)
# ============================================

resource "aws_autoscaling_policy" "scale_out" {
  count = var.enable_autoscaling ? 1 : 0

  name                   = "${var.cluster_name}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "scale_in" {
  count = var.enable_autoscaling ? 1 : 0

  name                   = "${var.cluster_name}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}
