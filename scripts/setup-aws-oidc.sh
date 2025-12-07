#!/bin/bash

# AWS OIDC Setup Script for GitHub Actions
# This script creates the necessary AWS resources for GitHub Actions OIDC authentication

set -e

echo "=========================================="
echo "AWS OIDC Setup for GitHub Actions"
echo "=========================================="
echo ""

# Configuration
read -p "Enter your AWS Account ID: " AWS_ACCOUNT_ID
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter your GitHub repository name: " GITHUB_REPO
read -p "Enter AWS region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

REPO_PATH="$GITHUB_USERNAME/$GITHUB_REPO"

echo ""
echo "Configuration:"
echo "  AWS Account ID: $AWS_ACCOUNT_ID"
echo "  GitHub Repo: $REPO_PATH"
echo "  AWS Region: $AWS_REGION"
echo ""
read -p "Is this correct? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Step 1: Creating OIDC Provider..."

# Check if OIDC provider already exists
OIDC_PROVIDER_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" 2>/dev/null; then
    echo "✅ OIDC provider already exists"
else
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
        --region $AWS_REGION
    echo "✅ OIDC provider created"
fi

echo ""
echo "Step 2: Creating IAM roles for each environment..."

# Function to create IAM role
create_role() {
    local ENV=$1
    local ROLE_NAME="GitHubActions-Terraform-$ENV"
    
    echo "Creating role: $ROLE_NAME"
    
    # Create trust policy
    cat > /tmp/trust-policy-$ENV.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$REPO_PATH:*"
        }
      }
    }
  ]
}
EOF

    # Create role
    if aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
        echo "  Role already exists, updating trust policy..."
        aws iam update-assume-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-document file:///tmp/trust-policy-$ENV.json
    else
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file:///tmp/trust-policy-$ENV.json \
            --description "Role for GitHub Actions to deploy Terraform to $ENV"
    fi
    
    # Attach AdministratorAccess policy (you may want to restrict this in production)
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
    
    echo "  ✅ Role created: arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME"
    
    # Clean up
    rm /tmp/trust-policy-$ENV.json
}

# Create roles for each environment
create_role "Dev"
create_role "Staging"
create_role "Prod"

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Add these secrets to your GitHub repository:"
echo ""
echo "AWS_ROLE_ARN_DEV:"
echo "  arn:aws:iam::$AWS_ACCOUNT_ID:role/GitHubActions-Terraform-Dev"
echo ""
echo "AWS_ROLE_ARN_STAGING:"
echo "  arn:aws:iam::$AWS_ACCOUNT_ID:role/GitHubActions-Terraform-Staging"
echo ""
echo "AWS_ROLE_ARN_PROD:"
echo "  arn:aws:iam::$AWS_ACCOUNT_ID:role/GitHubActions-Terraform-Prod"
echo ""
echo "To add secrets:"
echo "1. Go to: https://github.com/$REPO_PATH/settings/secrets/actions"
echo "2. Click 'New repository secret'"
echo "3. Add each secret above"
echo ""
echo "⚠️  SECURITY NOTE:"
echo "The roles currently have AdministratorAccess."
echo "For production, consider using least-privilege policies."
echo ""
