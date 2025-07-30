# Terraform Infrastructure for Patient Web Interface

This directory contains Terraform configuration files to deploy the Patient Web Interface application on AWS with a highly available and scalable architecture.

## Architecture Overview

The infrastructure includes:

- **VPC**: Custom Virtual Private Cloud with public and private subnets across 2 Availability Zones
- **Subnets**: 
  - 2 Public subnets for load balancer and NAT gateway
  - 2 Private subnets for application instances (future use)
- **Internet Gateway**: For public internet access
- **NAT Gateway**: For outbound internet access from private subnets
- **Application Load Balancer**: Distributes traffic across EC2 instances
- **Auto Scaling Group**: Automatically scales EC2 instances based on demand
- **Security Groups**: Firewall rules for web and database tiers
- **EC2 Instances**: Running the containerized Flask application
- **CloudWatch**: Monitoring and auto-scaling triggers

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **SSH key pair** for EC2 access
4. **Docker image** pushed to DockerHub

## Quick Start

### 1. Install Terraform

**Windows (using Chocolatey):**
```powershell
choco install terraform
```

**Windows (Manual):**
1. Download from [terraform.io](https://www.terraform.io/downloads.html)
2. Extract to a directory in your PATH

### 2. Configure AWS Credentials

```powershell
aws configure
```

Or set environment variables:
```powershell
$env:AWS_ACCESS_KEY_ID="your_access_key"
$env:AWS_SECRET_ACCESS_KEY="your_secret_key"
$env:AWS_DEFAULT_REGION="us-east-1"
```

### 3. Generate SSH Key Pair

```powershell
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

### 4. Configure Variables

Copy and edit the variables file:
```powershell
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and update:
- `public_key`: Your SSH public key content
- `aws_region`: Your preferred AWS region
- `docker_image`: Your DockerHub image name

### 5. Deploy Infrastructure

```powershell
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 6. Access Your Application

After deployment, Terraform will output the Application Load Balancer DNS name:
```
application_url = "http://patient-web-interface-alb-1234567890.us-east-1.elb.amazonaws.com"
```

## Configuration Files

### main.tf
Contains the main infrastructure resources:
- VPC and networking components
- Security groups
- EC2 launch template and Auto Scaling Group
- Application Load Balancer
- CloudWatch alarms

### variables.tf
Defines all configurable variables with descriptions and default values.

### outputs.tf
Defines output values that will be displayed after deployment.

### user-data.sh
Bootstrap script that runs on EC2 instances to:
- Install Docker and CloudWatch agent
- Pull and run the application container
- Configure monitoring and logging

### terraform.tfvars.example
Example configuration file with sample values.

## Customization

### Scaling Configuration

Modify auto-scaling parameters in `terraform.tfvars`:
```hcl
min_instances     = 2
max_instances     = 10
desired_instances = 3
```

### Instance Type

Change EC2 instance type:
```hcl
instance_type = "t3.small"  # or t3.medium, t3.large, etc.
```

### Network Configuration

Modify CIDR blocks for different IP ranges:
```hcl
vpc_cidr                = "172.16.0.0/16"
public_subnet_1_cidr    = "172.16.1.0/24"
public_subnet_2_cidr    = "172.16.2.0/24"
# ...
```

## Monitoring and Logs

### CloudWatch Metrics
The infrastructure automatically sets up CloudWatch monitoring for:
- CPU utilization
- Memory usage
- Disk usage
- Network statistics

### Auto Scaling
- Scale up when CPU > 80% for 2 consecutive periods
- Scale down when CPU < 20% for 2 consecutive periods

### Application Logs
Logs are available through:
- CloudWatch Logs (if configured in the application)
- SSH into instances and check Docker logs:
  ```bash
  docker logs patient-app
  ```

## Security

### Security Groups
- **Web Security Group**: Allows HTTP (80), HTTPS (443), Flask app (5000), and SSH (22) from VPC
- **Database Security Group**: Allows database connections only from web tier

### Access Control
- EC2 instances have IAM roles for CloudWatch and Systems Manager
- SSH access is restricted to VPC CIDR range
- Public subnets only contain load balancer and NAT gateway

## Maintenance

### Updates
To update the application:
1. Push new Docker image to DockerHub
2. Update `docker_image` variable
3. Run `terraform apply`
4. Auto Scaling Group will perform rolling updates

### Backups
- Consider setting up automated EBS snapshots
- Implement database backup strategy for production

### Monitoring
- Set up CloudWatch dashboards
- Configure SNS notifications for alarms
- Implement log aggregation

## Cost Optimization

### Development Environment
For development, use smaller resources:
```hcl
instance_type     = "t3.nano"
min_instances     = 1
max_instances     = 1
desired_instances = 1
```

### Production Considerations
- Use Reserved Instances for predictable workloads
- Implement lifecycle policies for logs
- Consider using Spot Instances for non-critical workloads

## Troubleshooting

### Common Issues

1. **Key Pair Error**
   - Ensure your public key is correctly formatted in `terraform.tfvars`
   - The key should start with `ssh-rsa` or `ssh-ed25519`

2. **Permission Denied**
   - Check AWS credentials and permissions
   - Ensure IAM user has EC2, VPC, and ELB permissions

3. **Resource Limits**
   - Check AWS service limits in your region
   - Some regions have lower default limits

4. **Application Not Starting**
   - Check user-data logs: `sudo cat /var/log/cloud-init-output.log`
   - Check Docker logs: `docker logs patient-app`

### Useful Commands

```powershell
# Check Terraform state
terraform show

# Destroy infrastructure
terraform destroy

# Format Terraform files
terraform fmt

# Validate configuration
terraform validate

# Show planned changes
terraform plan -detailed-exitcode
```

## Production Checklist

Before deploying to production:

- [ ] Update default passwords and secrets
- [ ] Configure SSL/TLS certificates
- [ ] Set up proper backup strategies
- [ ] Configure log retention policies
- [ ] Implement proper monitoring and alerting
- [ ] Review security group rules
- [ ] Set up proper DNS with Route53
- [ ] Configure automated patching
- [ ] Implement disaster recovery procedures
- [ ] Set up cost monitoring and budgets

## Support

For issues related to:
- **Infrastructure**: Check AWS CloudFormation events and CloudWatch logs
- **Application**: Check application logs and container status
- **Terraform**: Run `terraform plan` to see pending changes

## License

This infrastructure code is part of the Patient Web Interface project.
