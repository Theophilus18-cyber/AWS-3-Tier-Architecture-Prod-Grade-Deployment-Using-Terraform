#!/bin/bash

# AWS OIDC Setup Script for GitHub Actions
# This script automates the creation of OIDC provider and IAM roles

set -e

echo "🚀 AWS OIDC Setup for GitHub Actions"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

print_success "AWS CLI is installed"

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

print_success "AWS credentials are configured"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_info "AWS Account ID: $AWS_ACCOUNT_ID"
echo ""

# Prompt for GitHub repository information
echo "📝 Please provide your GitHub repository information:"
echo ""
read -p "Enter your GitHub username (e.g., Theophilus18-cyber): " GITHUB_USERNAME
read -p "Enter your repository name (e.g., AWS-3-Tier-Architecture-Prod-Grade-Deployment-Using-Terraform): " REPO_NAME

echo ""
print_info "Repository: $GITHUB_USERNAME/$REPO_NAME"
echo ""

# Confirm before proceeding
read -p "Is this information correct? (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    print_error "Setup cancelled by user"
    exit 1
fi

echo ""
echo "🔧 Starting OIDC setup..."
echo ""

# Step 1: Create OIDC Provider
echo "Step 1: Creating OIDC Provider..."
if aws iam list-open-id-connect-providers | grep -q "token.actions.githubusercontent.com"; then
    print_warning "OIDC Provider already exists, skipping creation"
else
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
        &> /dev/null
    print_success "OIDC Provider created"
fi
echo ""

# Step 2: Create Trust Policy Documents
echo "Step 2: Creating trust policy documents..."

# Create temporary directory for policies
mkdir -p /tmp/oidc-policies

# DEV Trust Policy
cat > /tmp/oidc-policies/trust-policy-dev.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/${REPO_NAME}:ref:refs/heads/dev"
        }
      }
    }
  ]
}
EOF

# STAGING Trust Policy
cat > /tmp/oidc-policies/trust-policy-staging.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/${REPO_NAME}:ref:refs/heads/staging"
        }
      }
    }
  ]
}
EOF

# PROD Trust Policy
cat > /tmp/oidc-policies/trust-policy-prod.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/${REPO_NAME}:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

print_success "Trust policy documents created"
echo ""

# Step 3: Create IAM Roles
echo "Step 3: Creating IAM roles..."

# Function to create role
create_role() {
    local ROLE_NAME=$1
    local POLICY_FILE=$2
    local ENV=$3
    
    if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
        print_warning "$ENV role already exists, skipping creation"
    else
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document "file://$POLICY_FILE" \
            --description "Role for GitHub Actions to deploy to $ENV environment" \
            &> /dev/null
        print_success "$ENV role created"
    fi
    
    # Attach policy
    if aws iam list-attached-role-policies --role-name "$ROLE_NAME" | grep -q "AdministratorAccess"; then
        print_warning "$ENV role already has AdministratorAccess policy"
    else
        aws iam attach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
            &> /dev/null
        print_success "AdministratorAccess policy attached to $ENV role"
    fi
}

create_role "GitHubActions-Terraform-Dev" "/tmp/oidc-policies/trust-policy-dev.json" "DEV"
create_role "GitHubActions-Terraform-Staging" "/tmp/oidc-policies/trust-policy-staging.json" "STAGING"
create_role "GitHubActions-Terraform-Prod" "/tmp/oidc-policies/trust-policy-prod.json" "PROD"

echo ""

# Step 4: Get Role ARNs
echo "Step 4: Retrieving Role ARNs..."
echo ""

DEV_ARN=$(aws iam get-role --role-name GitHubActions-Terraform-Dev --query 'Role.Arn' --output text)
STAGING_ARN=$(aws iam get-role --role-name GitHubActions-Terraform-Staging --query 'Role.Arn' --output text)
PROD_ARN=$(aws iam get-role --role-name GitHubActions-Terraform-Prod --query 'Role.Arn' --output text)

echo "════════════════════════════════════════════════════════════════"
echo "🎉 OIDC Setup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Add these secrets to your GitHub repository:"
echo "   Go to: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/secrets/actions"
echo ""
echo "   Secret Name: AWS_ROLE_ARN_DEV"
echo "   Secret Value: $DEV_ARN"
echo ""
echo "   Secret Name: AWS_ROLE_ARN_STAGING"
echo "   Secret Value: $STAGING_ARN"
echo ""
echo "   Secret Name: AWS_ROLE_ARN_PROD"
echo "   Secret Value: $PROD_ARN"
echo ""
echo "2. Copy the ARNs above and paste them as GitHub secrets"
echo ""
echo "3. Test the setup by running the GitHub Actions workflow"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

# Save ARNs to a file for reference
cat > github-secrets.txt <<EOF
GitHub Secrets Configuration
=============================

Add these secrets to your GitHub repository:
https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/secrets/actions

Secret 1:
Name:  AWS_ROLE_ARN_DEV
Value: $DEV_ARN

Secret 2:
Name:  AWS_ROLE_ARN_STAGING
Value: $STAGING_ARN

Secret 3:
Name:  AWS_ROLE_ARN_PROD
Value: $PROD_ARN

Setup completed on: $(date)
AWS Account ID: $AWS_ACCOUNT_ID
Repository: $GITHUB_USERNAME/$REPO_NAME
EOF

print_success "ARNs saved to github-secrets.txt for your reference"
echo ""

# Cleanup
rm -rf /tmp/oidc-policies

print_success "Setup complete! 🎉"
