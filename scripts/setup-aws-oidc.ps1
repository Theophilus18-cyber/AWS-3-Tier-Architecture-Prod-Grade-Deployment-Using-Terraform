# PowerShell script for Windows users to set up AWS OIDC for GitHub Actions

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "AWS OIDC Setup for GitHub Actions" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$AWS_ACCOUNT_ID = Read-Host "Enter your AWS Account ID"
$GITHUB_USERNAME = Read-Host "Enter your GitHub username"
$GITHUB_REPO = Read-Host "Enter your GitHub repository name"
$AWS_REGION = Read-Host "Enter AWS region (default: us-east-1)"
if ([string]::IsNullOrWhiteSpace($AWS_REGION)) {
    $AWS_REGION = "us-east-1"
}

$REPO_PATH = "$GITHUB_USERNAME/$GITHUB_REPO"

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  AWS Account ID: $AWS_ACCOUNT_ID"
Write-Host "  GitHub Repo: $REPO_PATH"
Write-Host "  AWS Region: $AWS_REGION"
Write-Host ""

$CONFIRM = Read-Host "Is this correct? (yes/no)"
if ($CONFIRM -ne "yes") {
    Write-Host "Aborted." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 1: Creating OIDC Provider..." -ForegroundColor Green

# Check if OIDC provider already exists
$OIDC_PROVIDER_ARN = "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

try {
    aws iam get-open-id-connect-provider --open-id-connect-provider-arn $OIDC_PROVIDER_ARN 2>$null
    Write-Host "OIDC provider already exists" -ForegroundColor Green
}
catch {
    aws iam create-open-id-connect-provider `
        --url https://token.actions.githubusercontent.com `
        --client-id-list sts.amazonaws.com `
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 `
        --region $AWS_REGION
    Write-Host " OIDC provider created" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 2: Creating IAM roles for each environment..." -ForegroundColor Green

# Function to create IAM role
function Create-GitHubActionsRole {
    param(
        [string]$Environment,
        [string]$AccountId,
        [string]$RepoPath
    )
    
    $ROLE_NAME = "GitHubActions-Terraform-$Environment"
    Write-Host "Creating role: $ROLE_NAME" -ForegroundColor Yellow
    
    # Create trust policy
    $TRUST_POLICY = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AccountId}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${RepoPath}:*"
        }
      }
    }
  ]
}
"@

    $TRUST_POLICY_FILE = "$env:TEMP\trust-policy-$Environment.json"
    $TRUST_POLICY | Out-File -FilePath $TRUST_POLICY_FILE -Encoding utf8
    
    # Create role
    try {
        aws iam get-role --role-name $ROLE_NAME 2>$null
        Write-Host "  Role already exists, updating trust policy..." -ForegroundColor Yellow
        aws iam update-assume-role-policy `
            --role-name $ROLE_NAME `
            --policy-document file://$TRUST_POLICY_FILE
    }
    catch {
        aws iam create-role `
            --role-name $ROLE_NAME `
            --assume-role-policy-document file://$TRUST_POLICY_FILE `
            --description "Role for GitHub Actions to deploy Terraform to $Environment"
    }
    
    # Attach AdministratorAccess policy
    aws iam attach-role-policy `
        --role-name $ROLE_NAME `
        --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
    
    Write-Host "   Role created: arn:aws:iam::${AccountId}:role/$ROLE_NAME" -ForegroundColor Green
    
    # Clean up
    Remove-Item $TRUST_POLICY_FILE -ErrorAction SilentlyContinue
}

# Create roles for each environment
Create-GitHubActionsRole -Environment "Dev" -AccountId $AWS_ACCOUNT_ID -RepoPath $REPO_PATH
Create-GitHubActionsRole -Environment "Staging" -AccountId $AWS_ACCOUNT_ID -RepoPath $REPO_PATH
Create-GitHubActionsRole -Environment "Prod" -AccountId $AWS_ACCOUNT_ID -RepoPath $REPO_PATH

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Add these secrets to your GitHub repository:" -ForegroundColor Yellow
Write-Host ""
Write-Host "AWS_ROLE_ARN_DEV:" -ForegroundColor White
Write-Host "  arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActions-Terraform-Dev" -ForegroundColor Cyan
Write-Host ""
Write-Host "AWS_ROLE_ARN_STAGING:" -ForegroundColor White
Write-Host "  arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActions-Terraform-Staging" -ForegroundColor Cyan
Write-Host ""
Write-Host "AWS_ROLE_ARN_PROD:" -ForegroundColor White
Write-Host "  arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActions-Terraform-Prod" -ForegroundColor Cyan
Write-Host ""
Write-Host "To add secrets:" -ForegroundColor Yellow
Write-Host "1. Go to: https://github.com/$REPO_PATH/settings/secrets/actions"
Write-Host "2. Click 'New repository secret'"
Write-Host "3. Add each secret above"
Write-Host ""
Write-Host "  SECURITY NOTE:" -ForegroundColor Red
Write-Host "The roles currently have AdministratorAccess."
Write-Host "For production, consider using least-privilege policies."
Write-Host ""

# Copy ARNs to clipboard (optional)
$ARNS = @"
AWS_ROLE_ARN_DEV=arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActions-Terraform-Dev
AWS_ROLE_ARN_STAGING=arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActions-Terraform-Staging
AWS_ROLE_ARN_PROD=arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActions-Terraform-Prod
"@

Write-Host "Would you like to copy the ARNs to clipboard? (yes/no)" -ForegroundColor Yellow
$COPY = Read-Host
if ($COPY -eq "yes") {
    $ARNS | Set-Clipboard
    Write-Host " ARNs copied to clipboard!" -ForegroundColor Green
}
