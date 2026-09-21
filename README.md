# AWS Cloud Infrastructure for a User Management Application

This repository provisions the AWS infrastructure used to run a three-tier user-management application. The infrastructure is defined with Terraform and deploys the application from a Git repository during instance startup.

The focus of this project is the DevOps implementation: network segmentation, automated instance bootstrap, load balancing, autoscaling, managed database hosting, and security-group-based access control.

## Architecture

```text
Internet
   |\
   | \-- HTTP :80 --> Frontend EC2 (public subnet) --> Nginx serves Angular
   |
   \---- HTTP :80 --> Application Load Balancer (two public subnets)
                              |
                              \--> Backend Auto Scaling Group (private subnets, :3000)
                                               |
                                               \--> Amazon RDS MySQL (private subnets, :3306)
```

The frontend is deployed separately on a public EC2 instance. During bootstrap it reads the load balancer DNS name from AWS Systems Manager Parameter Store, injects it into the production Angular configuration, builds the frontend, and serves it with Nginx.

## What Terraform Provisions

| Area | Resources in this project |
| --- | --- |
| Network | One VPC (`10.0.0.0/16`), two public subnets, two private subnets, an Internet Gateway, a NAT Gateway, and public/private route tables |
| Frontend | One Ubuntu EC2 instance in a public subnet, with a public IP and Nginx |
| API | Internet-facing Application Load Balancer, HTTP listener, target group, launch template, and EC2 Auto Scaling Group |
| Scaling | Backend desired capacity of 2, minimum 1, maximum 4, with target tracking at 70% average CPU utilization |
| Data | Private Amazon RDS MySQL instance with 20 GB allocated storage and a private DB subnet group |
| Configuration | SSM Parameter Store entry containing the ALB DNS name |
| Access | SSH key pair and security groups for the frontend, load balancer, backend, and database |

## Network and Access Controls

The security groups restrict inbound paths as follows:

| Target | Allowed inbound traffic |
| --- | --- |
| Frontend EC2 | HTTP (80) from the internet; SSH (22) only from `my_ip` |
| ALB | HTTP (80) from the internet |
| Backend instances | Application port (default `3000`) only from the ALB security group |
| RDS MySQL | MySQL (3306) only from the backend security group |

Backend instances and the RDS database have no public IP addresses. Private-subnet outbound access is routed through the NAT Gateway.

## Bootstrap and Deployment

Terraform renders the two user-data scripts in [`terraform/`](terraform):

- [`user_data_frontend.sh`](terraform/user_data_frontend.sh) installs Node.js, Nginx, Git, and the AWS CLI; clones the repository; obtains the ALB URL from Parameter Store; builds the Angular application; and publishes the build with Nginx.
- [`user_data_backend.sh`](terraform/user_data_backend.sh) installs Node.js and Git; clones the repository; writes the database connection settings and application port to `.env`; installs dependencies; and starts the Node.js API with PM2.

The backend target group checks `GET /health` every 30 seconds. Instances must return HTTP 200 to be considered healthy by the load balancer.

## Prerequisites

- Terraform 1.0 or later
- AWS credentials configured for the target account and region
- An existing SSH public key
- A Git repository URL that the instances can clone
- The `LabInstanceProfile` IAM instance profile available in the AWS account (the frontend instance references it)

## Deploy the Infrastructure

From the repository root, create a local `terraform/terraform.tfvars` file. Do not commit database passwords or other secrets.

```hcl
aws_region      = "us-east-1"
project_name    = "projet-cloud"
my_ip           = "203.0.113.10"
github_repo     = "https://github.com/your-account/your-repository.git"
public_key_path = "C:/Users/your-user/.ssh/projet-cloud-key.pub"
key_pair_name   = "projet-cloud-key"

db_name     = "appdb"
db_username = "admin"
db_password = "use-a-secure-password"
```

Then initialize, review, and apply the Terraform configuration:

```powershell
cd terraform
terraform init
terraform plan
terraform apply
```

After the apply completes, retrieve the deployed entry points:

```powershell
terraform output
```

Available outputs include the frontend URL and public IP, ALB URL, RDS endpoint, and an SSH command for the frontend instance.

## Key Configuration Inputs

Required values are `my_ip`, `github_repo`, and `db_password`. Other important defaults include:

| Variable | Default |
| --- | --- |
| `aws_region` | `us-east-1` |
| `instance_type` | `t2.micro` |
| `app_port` | `3000` |
| `db_engine` | `mysql` |
| `db_engine_version` | `8.0` |

See [`terraform/variables.tf`](terraform/variables.tf) for the complete variable definitions.

## Repository Layout

```text
terraform/  Infrastructure as code, networking, security groups, EC2, ALB/ASG, RDS, outputs, and bootstrap scripts
frontend/   Angular application built and served by the frontend EC2 instance
backend/    Node.js API deployed to the private backend instances
```

## Cleanup

To delete all Terraform-managed AWS resources when they are no longer needed:

```powershell
cd terraform
terraform destroy
```

This removes the deployed infrastructure, including the RDS instance. The current RDS configuration is set to skip the final snapshot, so destroy should be used only when data retention is not required.
