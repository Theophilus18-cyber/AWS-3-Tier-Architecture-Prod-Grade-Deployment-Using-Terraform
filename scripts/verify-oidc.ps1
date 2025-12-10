# AWS OIDC Verification Script (PowerShell)
# This script verifies that OIDC and IAM roles are set up correctly

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "🔍 AWS OIDC Setup Verification" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# Function to print colored output
function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow
}

$allChecks = $true

# Check 1: AWS CLI
Write-Host "1. Checking AWS CLI installation..." -ForegroundColor Cyan
try {
    $awsVersion = aws --version 2>&1
    Write-Success "AWS CLI is installed: $awsVersion"
} catch {
    Write-Failure "AWS CLI is not installed"
    $allChecks = $false
}
Write-Host ""

# Check 2: AWS Credentials
Write-Host "2. Checking AWS credentials..." -ForegroundColor Cyan
try {
    $identity = aws sts get-caller-identity | ConvertFrom-Json
    Write-Success "AWS credentials are configured"
    Write-Info "Account ID: $($identity.Account)"
    Write-Info "User/Role: $($identity.Arn)"
    $AWS_ACCOUNT_ID = $identity.Account
} catch {
    Write-Failure "AWS credentials are not configured"
    $allChecks = $false
    $AWS_ACCOUNT_ID = "UNKNOWN"
}
Write-Host ""

# Check 3: OIDC Provider
Write-Host "3. Checking OIDC Provider..." -ForegroundColor Cyan
try {
    $providers = aws iam list-open-id-connect-providers | ConvertFrom-Json
    $githubProvider = $providers.OpenIDConnectProviderList | Where-Object { $_.Arn -like "*token.actions.githubusercontent.com*" }
    
    if ($githubProvider) {
        Write-Success "OIDC Provider exists"
        Write-Info "ARN: $($githubProvider.Arn)"
    } else {
        Write-Failure "OIDC Provider NOT found"
        Write-Host "   Run setup-oidc.ps1 to create it" -ForegroundColor Yellow
        $allChecks = $false
    }
} catch {
    Write-Failure "Error checking OIDC Provider: $_"
    $allChecks = $false
}
Write-Host ""

# Check 4: IAM Roles
Write-Host "4. Checking IAM Roles..." -ForegroundColor Cyan

function Check-IAMRole {
    param(
        [string]$RoleName,
        [string]$Environment
    )
    
    try {
        $role = aws iam get-role --role-name $RoleName 2>$null | ConvertFrom-Json
        Write-Success "$Environment role exists: $RoleName"
        Write-Info "ARN: $($role.Role.Arn)"
        
        # Check attached policies
        $policies = aws iam list-attached-role-policies --role-name $RoleName | ConvertFrom-Json
        $hasAdminAccess = $policies.AttachedPolicies | Where-Object { $_.PolicyName -eq "AdministratorAccess" }
        
        if ($hasAdminAccess) {
            Write-Success "  ✓ AdministratorAccess policy attached"
        } else {
            Write-Failure "  ✗ AdministratorAccess policy NOT attached"
            $script:allChecks = $false
        }
        
        return $role.Role.Arn
    } catch {
        Write-Failure "$Environment role NOT found: $RoleName"
        Write-Host "   Run setup-oidc.ps1 to create it" -ForegroundColor Yellow
        $script:allChecks = $false
        return $null
    }
}

$DEV_ARN = Check-IAMRole -RoleName "GitHubActions-Terraform-Dev" -Environment "DEV"
Write-Host ""
$STAGING_ARN = Check-IAMRole -RoleName "GitHubActions-Terraform-Staging" -Environment "STAGING"
Write-Host ""
$PROD_ARN = Check-IAMRole -RoleName "GitHubActions-Terraform-Prod" -Environment "PROD"
Write-Host ""

# Check 5: Trust Policies
Write-Host "5. Checking Trust Policies..." -ForegroundColor Cyan

function Check-TrustPolicy {
    param(
        [string]$RoleName,
        [string]$Environment
    )
    
    try {
        $role = aws iam get-role --role-name $RoleName 2>$null | ConvertFrom-Json
        $trustPolicy = $role.Role.AssumeRolePolicyDocument
        
        # Check if trust policy contains GitHub OIDC provider
        $policyJson = $trustPolicy | ConvertTo-Json -Depth 10
        
        if ($policyJson -like "*token.actions.githubusercontent.com*") {
            Write-Success "$Environment trust policy configured for GitHub OIDC"
            
            # Extract repository from trust policy
            if ($policyJson -match "repo:([^:]+):") {
                Write-Info "  Repository: $($Matches[1])"
            }
        } else {
            Write-Failure "$Environment trust policy does NOT include GitHub OIDC"
            $script:allChecks = $false
        }
    } catch {
        Write-Failure "Error checking $Environment trust policy: $_"
        $script:allChecks = $false
    }
}

Check-TrustPolicy -RoleName "GitHubActions-Terraform-Dev" -Environment "DEV"
Check-TrustPolicy -RoleName "GitHubActions-Terraform-Staging" -Environment "STAGING"
Check-TrustPolicy -RoleName "GitHubActions-Terraform-Prod" -Environment "PROD"
Write-Host ""

# Summary
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
if ($allChecks) {
    Write-Host "🎉 All checks passed!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 GitHub Secrets to Add:" -ForegroundColor Cyan
    Write-Host ""
    if ($DEV_ARN) {
        Write-Host "Secret Name: AWS_ROLE_ARN_DEV" -ForegroundColor White
        Write-Host "Secret Value: $DEV_ARN" -ForegroundColor Yellow
        Write-Host ""
    }
    if ($STAGING_ARN) {
        Write-Host "Secret Name: AWS_ROLE_ARN_STAGING" -ForegroundColor White
        Write-Host "Secret Value: $STAGING_ARN" -ForegroundColor Yellow
        Write-Host ""
    }
    if ($PROD_ARN) {
        Write-Host "Secret Name: AWS_ROLE_ARN_PROD" -ForegroundColor White
        Write-Host "Secret Value: $PROD_ARN" -ForegroundColor Yellow
        Write-Host ""
    }
    Write-Host "Add these at: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions" -ForegroundColor Cyan
} else {
    Write-Host "❌ Some checks failed!" -ForegroundColor Red
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please run setup-oidc.ps1 to fix the issues" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
