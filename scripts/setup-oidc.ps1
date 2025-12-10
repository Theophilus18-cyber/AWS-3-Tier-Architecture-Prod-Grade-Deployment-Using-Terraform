# AWS OIDC Setup Script for GitHub Actions (PowerShell)
# This script automates the creation of OIDC provider and IAM roles

# Don't stop on errors - we handle them manually
$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "AWS OIDC Setup for GitHub Actions" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is installed
$awsVersion = aws --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] AWS CLI is not installed." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] AWS CLI is installed" -ForegroundColor Green

# Check if AWS credentials are configured
$null = aws sts get-caller-identity 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] AWS credentials not configured. Run 'aws configure' first." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] AWS credentials are configured" -ForegroundColor Green

# Get AWS Account ID
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
Write-Host "[INFO] AWS Account ID: $AWS_ACCOUNT_ID" -ForegroundColor Yellow
Write-Host ""

# Prompt for GitHub info
Write-Host "Please provide your GitHub repository information:" -ForegroundColor Cyan
$GITHUB_USERNAME = Read-Host "Enter your GitHub username"
$REPO_NAME = Read-Host "Enter your repository name"

Write-Host ""
Write-Host "[INFO] Repository: $GITHUB_USERNAME/$REPO_NAME" -ForegroundColor Yellow

$CONFIRM = Read-Host "Is this correct? (y/n)"
if ($CONFIRM -ne "y") {
    Write-Host "[CANCELLED]" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Starting OIDC setup..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Create OIDC Provider
Write-Host "Step 1: Creating OIDC Provider..."
$providers = aws iam list-open-id-connect-providers --output text 2>&1
if ($providers -like "*token.actions.githubusercontent.com*") {
    Write-Host "[SKIP] OIDC Provider already exists" -ForegroundColor Yellow
} else {
    $null = aws iam create-open-id-connect-provider --url "https://token.actions.githubusercontent.com" --client-id-list "sts.amazonaws.com" --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" 2>&1
    Write-Host "[OK] OIDC Provider created" -ForegroundColor Green
}
Write-Host ""

# Step 2: Create Trust Policy Files
Write-Host "Step 2: Creating trust policy documents..."

$tempDir = "$env:TEMP\oidc-setup"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# JSON trust policy template
$policyTemplate = '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:GITHUB_USER/REPO_NAME:*"
                }
            }
        }
    ]
}'

# Replace placeholders and save
$policy = $policyTemplate.Replace("ACCOUNT_ID", $AWS_ACCOUNT_ID).Replace("GITHUB_USER", $GITHUB_USERNAME).Replace("REPO_NAME", $REPO_NAME)
[System.IO.File]::WriteAllText("$tempDir\policy-dev.json", $policy)
[System.IO.File]::WriteAllText("$tempDir\policy-staging.json", $policy)
[System.IO.File]::WriteAllText("$tempDir\policy-prod.json", $policy)

Write-Host "[OK] Trust policy documents created" -ForegroundColor Green
Write-Host ""

# Step 3: Create IAM Roles
Write-Host "Step 3: Creating IAM roles..."

$roles = @(
    @{Name="GitHubActions-Terraform-Dev"; Policy="$tempDir\policy-dev.json"; Env="DEV"},
    @{Name="GitHubActions-Terraform-Staging"; Policy="$tempDir\policy-staging.json"; Env="STAGING"},
    @{Name="GitHubActions-Terraform-Prod"; Policy="$tempDir\policy-prod.json"; Env="PROD"}
)

foreach ($role in $roles) {
    $roleName = $role.Name
    $policyFile = $role.Policy
    $env = $role.Env
    
    # Check if role exists
    $null = aws iam get-role --role-name $roleName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SKIP] $env role already exists" -ForegroundColor Yellow
    } else {
        # Create role
        $null = aws iam create-role --role-name $roleName --assume-role-policy-document "file://$policyFile" --description "GitHub Actions $env role" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] $env role created" -ForegroundColor Green
            # Attach admin policy
            $null = aws iam attach-role-policy --role-name $roleName --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] AdministratorAccess attached to $env" -ForegroundColor Green
            }
        } else {
            Write-Host "[ERROR] Failed to create $env role" -ForegroundColor Red
        }
    }
}

Write-Host ""

# Step 4: Get Role ARNs
Write-Host "Step 4: Retrieving Role ARNs..."

$DEV_ARN = aws iam get-role --role-name GitHubActions-Terraform-Dev --query "Role.Arn" --output text 2>&1
$STAGING_ARN = aws iam get-role --role-name GitHubActions-Terraform-Staging --query "Role.Arn" --output text 2>&1
$PROD_ARN = aws iam get-role --role-name GitHubActions-Terraform-Prod --query "Role.Arn" --output text 2>&1

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "OIDC Setup Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Add these secrets to GitHub:" -ForegroundColor Cyan
Write-Host "https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/secrets/actions" -ForegroundColor Yellow
Write-Host ""
Write-Host "AWS_ROLE_ARN_DEV     = $DEV_ARN" -ForegroundColor White
Write-Host "AWS_ROLE_ARN_STAGING = $STAGING_ARN" -ForegroundColor White
Write-Host "AWS_ROLE_ARN_PROD    = $PROD_ARN" -ForegroundColor White
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green

# Save to file
@"
GitHub Secrets for OIDC
=======================
Repository: $GITHUB_USERNAME/$REPO_NAME

AWS_ROLE_ARN_DEV=$DEV_ARN
AWS_ROLE_ARN_STAGING=$STAGING_ARN
AWS_ROLE_ARN_PROD=$PROD_ARN

URL: https://github.com/$GITHUB_USERNAME/$REPO_NAME/settings/secrets/actions
"@ | Out-File -FilePath "$PSScriptRoot\..\github-secrets.txt" -Encoding ascii

Write-Host "[OK] Saved to github-secrets.txt" -ForegroundColor Green

# Cleanup
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Read-Host "Press Enter to exit"
