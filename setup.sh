#!/bin/bash

# Setup script for 3-Tier AWS Infrastructure
# This script helps you configure your environment securely

echo "🚀 Setting up 3-Tier AWS Infrastructure with Terraform"
echo "======================================================"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first:"
    echo "   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first:"
    echo "   https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "⚠️  AWS credentials not configured. Let's set them up:"
    echo ""
    echo "You can configure AWS credentials in several ways:"
    echo "1. Run 'aws configure' to set up credentials"
    echo "2. Set environment variables:"
    echo "   export AWS_ACCESS_KEY_ID='your-access-key'"
    echo "   export AWS_SECRET_ACCESS_KEY='your-secret-key'"
    echo "   export AWS_DEFAULT_REGION='us-east-1'"
    echo "3. Use IAM roles (if running on EC2)"
    echo ""
    read -p "Press Enter after configuring your AWS credentials..."
    
    # Check again
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "❌ AWS credentials still not configured. Please try again."
        exit 1
    fi
fi

echo "✅ AWS credentials configured"

# Show current AWS account
echo "🔐 Using AWS Account: $(aws sts get-caller-identity --query 'Account' --output text)"

# Create terraform.tfvars from example if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp example.tfvars terraform.tfvars
    echo "✅ Created terraform.tfvars"
    echo "⚠️  Please edit terraform.tfvars with your specific values before running terraform"
else
    echo "✅ terraform.tfvars already exists"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit terraform.tfvars with your specific values"
echo "2. Run 'terraform init' to initialize"
echo "3. Run 'terraform plan' to see what will be created"
echo "4. Run 'terraform apply' to deploy your infrastructure on aws"
echo ""
echo "⚠️  Remember: Never commit terraform.tfvars to version control" 