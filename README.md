# AWS Web Server Cluster Terraform Module

Creates a highly available web server cluster on AWS with Application Load Balancer and Auto Scaling.

## Features

- Application Load Balancer with health checks
- Auto Scaling Group with configurable min/max instances
- Security group chaining (instances only accessible via ALB)
- Customizable instance types per environment
- Deploy across multiple availability zones

## Usage

```hcl
module "webserver_cluster" {
  source = "github.com/your-username/terraform-aws-webserver-cluster?ref=v0.0.1"

  cluster_name  = "my-app"
  instance_type = "t3.micro"
  min_size      = 2
  max_size      = 5
  environment   = "dev"
}

output "alb_url" {
  value = module.webserver_cluster.alb_url
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name for all cluster resources | string | - | yes |
| instance_type | EC2 instance type | string | t3.micro | no |
| min_size | Minimum instances in ASG | number | 1 | no |
| max_size | Maximum instances in ASG | number | 5 | no |
| desired_capacity | Desired instances in ASG | number | 2 | no |
| server_port | HTTP port | number | 80 | no |
| environment | Environment name | string | dev | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | DNS name of the load balancer |
| alb_url | Full URL to access the cluster |
| asg_name | Name of the Auto Scaling Group |

## Gotchas

- **File paths:** Use `${path.module}` for any files referenced inside the module
- **Security group rules:** Uses separate resources for flexibility
- **Required variables:** `cluster_name` must be unique per deployment
```


