# shows what the module returns to the caller

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
  description = "IDS of the security groups created"
  value = {
    alb      = aws_security_group.alb.id
    instance = aws_security_group.instance.id
  }
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.web.arn
}
