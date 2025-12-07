# 3-Tier AWS Infrastructure with Terraform

This repository contains Terraform configurations for deploying a 3-tier AWS infrastructure including web, application, and database tiers.

## Architecture

- **Web Tier**: Public-facing load balancer and web servers
- **Application Tier**: Private application servers
- **Database Tier**: Private RDS database

## Security Features

- Security groups with least-privilege access
- Private subnets for application and database tiers
- Public subnets only for web tier
- Auto Scaling Groups for high availability

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- AWS credentials (Access Key ID and Secret Access Key)

## Setup Instructions

### 1. Configure AWS Credentials

**Option A: AWS CLI Configuration (Recommended)**
```bash
aws configure
```

**Option B: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

**Option C: Terraform Variables (Less Secure)**
Create a `terraform.tfvars` file (DO NOT commit this file):
```hcl
access_key = "your-access-key"
secret_key = "your-secret-key"
```

### 2. Configure Environment Variables

Copy the example configuration:
```bash
cp example.tfvars terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:
- Update `key_name` with your EC2 key pair name
- Set appropriate `db_password`
- Adjust instance types and sizes as needed

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. Destroy Infrastructure

```bash
terraform destroy
```

## Environment-Specific Configurations

The repository includes configurations for different environments:

- `environments/dev/` - Development environment
- `environments/staging/` - Staging environment  
- `environments/prod/` - Production environment

## Security Best Practices

1. **Never commit sensitive data** to version control
2. Use AWS IAM roles when possible instead of access keys
3. Rotate credentials regularly
4. Use AWS Secrets Manager for database passwords in production
5. Enable CloudTrail for audit logging
6. Use VPC Flow Logs for network monitoring

## File Structure

```
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output values
├── backend.tf              # Backend configuration
├── example.tfvars          # Example variable values
├── .gitignore              # Git ignore patterns
├── modules/
│   ├── network/            # VPC and subnet configuration
│   ├── security/           # Security groups
│   ├── compute/            # EC2 and Auto Scaling
│   ├── loadbalancer/       # Application Load Balancer
│   └── database/           # RDS database
└── environments/
    ├── dev/
    ├── staging/
    └── prod/
```

## Troubleshooting

### GitHub Push Protection Errors

If you encounter push protection errors due to detected secrets:

1. Remove any hardcoded credentials from your code
2. Use environment variables or AWS CLI configuration
3. Ensure `.tfvars` files are in `.gitignore`
4. If credentials were committed, rotate them immediately

### Common Issues

- **Access Denied**: Ensure your AWS credentials have sufficient permissions
- **VPC Limits**: Check your AWS account VPC limits
- **AMI Not Found**: Update the AMI ID for your region

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License. 