# outputs.tf - what the module returns to the caller

# ============================================
# EXISTING OUTPUTS
# ============================================

output "alb_dns_name" {
  description = "DNS name of the load balancer - use this to access your app"
  value       = aws_lb.web.dns_name
}

output "alb_url" {
  description = "Full URL to access the web cluster"
  value       = "http://${aws_lb.web.dns_name}"
}

output "asg_name" {
  description = "Name of the auto scaling group"
  value       = aws_autoscaling_group.web.name
}

output "security_group_ids" {
  description = "IDs of the security groups created"
  value = {
    alb      = aws_security_group.alb.id
    instance = aws_security_group.instance.id
  }
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.web.arn
}

# ============================================
# DAY 10: NEW OUTPUTS WITH FOR EXPRESSIONS
# ============================================

output "autoscaling_policies" {
  description = "Autoscaling policy names (only created if enabled)"
  value = var.enable_autoscaling ? {
    scale_out = aws_autoscaling_policy.scale_out[0].name
    scale_in  = aws_autoscaling_policy.scale_in[0].name
  } : {}
}

output "security_group_rules" {
  description = "Map of all security group rule IDs"
  value = {
    http_from_alb = aws_security_group_rule.allow_http_from_alb.id
    ssh           = var.enable_ssh ? aws_security_group_rule.allow_ssh[0].id : null
    additional    = { for key, rule in aws_security_group_rule.additional : key => rule.id }
  }
}

output "instance_tags_applied" {
  description = "All tags applied to EC2 instances (base + custom)"
  value = merge(
    {
      Name        = "${var.cluster_name}-instance"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.custom_instance_tags
  )
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.web.id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.web.arn
}

# ============================================
# FOR EXPRESSION EXAMPLES
# ============================================

output "all_security_group_rule_ids" {
  description = "List of all security group rule IDs (for expression example)"
  value = concat(
    [aws_security_group_rule.allow_http_from_alb.id],
    var.enable_ssh ? [aws_security_group_rule.allow_ssh[0].id] : [],
    [for rule in aws_security_group_rule.additional : rule.id]
  )
}

output "security_group_rule_summary" {
  description = "Summary of security group rules (for expression example)"
  value = {
    for key, rule in aws_security_group_rule.additional : key => {
      port     = rule.to_port
      protocol = rule.protocol
      desc     = rule.description
    }
  }
}
